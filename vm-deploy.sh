#!/bin/bash

# VM Auto-deploy script for Iris project
# This script deploys to Google VM via SSH

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration - UPDATE THESE VALUES
VM_USER="your-username"                    # Your VM username
VM_HOST="your-vm-ip"                       # Your VM external IP or hostname
VM_PORT="22"                               # SSH port (default 22)
SSH_KEY_PATH="$HOME/.ssh/id_rsa"          # Path to your SSH private key
VM_PROJECT_DIR="/home/$VM_USER/finaliris"  # Project directory on VM
LOCAL_PROJECT_DIR="/Users/ishaantheman/theirispanaroma"  # Local project directory

# Logging
LOG_DIR="/tmp/iris-vm-deploy-logs"
LOG_FILE="$LOG_DIR/vm-deploy-$(date +%Y%m%d-%H%M%S).log"
MAX_LOG_FILES=10

# Function to print colored output with timestamp
print_status() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[$timestamp]${NC} $message"
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

print_success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}✅ [$timestamp] $message${NC}"
    echo "[$timestamp] SUCCESS: $message" >> "$LOG_FILE"
}

print_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}❌ [$timestamp] $message${NC}"
    echo "[$timestamp] ERROR: $message" >> "$LOG_FILE"
}

print_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}⚠️  [$timestamp] $message${NC}"
    echo "[$timestamp] WARNING: $message" >> "$LOG_FILE"
}

print_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${CYAN}ℹ️  [$timestamp] $message${NC}"
    echo "[$timestamp] INFO: $message" >> "$LOG_FILE"
}

print_step() {
    local step="$1"
    local message="$2"
    echo -e "${PURPLE}🔄 [$step] $message${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] STEP $step: $message" >> "$LOG_FILE"
}

# Function to run SSH command
run_ssh() {
    local command="$1"
    local description="$2"
    
    print_info "Running on VM: $description"
    
    if ssh -i "$SSH_KEY_PATH" -p "$VM_PORT" -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" "$command"; then
        print_success "$description completed"
        return 0
    else
        print_error "$description failed"
        return 1
    fi
}

# Function to check SSH connection
check_ssh_connection() {
    print_info "Testing SSH connection to $VM_USER@$VM_HOST:$VM_PORT..."
    
    if ssh -i "$SSH_KEY_PATH" -p "$VM_PORT" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" "echo 'SSH connection successful'" >/dev/null 2>&1; then
        print_success "SSH connection established"
        return 0
    else
        print_error "Failed to connect to VM via SSH"
        print_info "Please check:"
        print_info "  - VM IP address: $VM_HOST"
        print_info "  - SSH key path: $SSH_KEY_PATH"
        print_info "  - VM username: $VM_USER"
        print_info "  - Firewall rules (port $VM_PORT)"
        return 1
    fi
}

# Function to sync code to VM
sync_code_to_vm() {
    print_step "1" "Syncing code to VM..."
    
    # Create project directory on VM if it doesn't exist
    run_ssh "mkdir -p $VM_PROJECT_DIR" "Creating project directory on VM"
    
    # Sync code using rsync (exclude git, logs, node_modules, etc.)
    print_info "Syncing project files to VM..."
    
    local rsync_cmd="rsync -avz --delete \
        --exclude='.git/' \
        --exclude='node_modules/' \
        --exclude='.venv/' \
        --exclude='__pycache__/' \
        --exclude='*.log' \
        --exclude='.env' \
        --exclude='.env.local' \
        --exclude='dist/' \
        --exclude='build/' \
        --exclude='*.pyc' \
        --exclude='.DS_Store' \
        -e 'ssh -i $SSH_KEY_PATH -p $VM_PORT -o StrictHostKeyChecking=no' \
        $LOCAL_PROJECT_DIR/ \
        $VM_USER@$VM_HOST:$VM_PROJECT_DIR/"
    
    if eval "$rsync_cmd"; then
        print_success "Code synced to VM successfully"
    else
        print_error "Failed to sync code to VM"
        return 1
    fi
}

# Function to deploy on VM
deploy_on_vm() {
    print_step "2" "Deploying on VM..."
    
    # Change to project directory and run deployment
    local deploy_commands="
        cd $VM_PROJECT_DIR && \
        echo '🚀 Starting deployment on VM...' && \
        echo '🔨 Building Docker containers...' && \
        docker compose build --no-cache && \
        echo '✅ Containers built successfully' && \
        echo '🛑 Stopping existing containers...' && \
        docker compose down && \
        echo '✅ Containers stopped' && \
        echo '🚀 Starting Iris services...' && \
        docker compose up -d && \
        echo '✅ Services started' && \
        echo '⏳ Waiting for services to initialize...' && \
        sleep 15 && \
        echo '🔍 Checking service status...' && \
        docker compose ps && \
        echo '🎉 Deployment completed on VM!'
    "
    
    if run_ssh "$deploy_commands" "VM deployment"; then
        print_success "Deployment completed on VM"
        return 0
    else
        print_error "Deployment failed on VM"
        return 1
    fi
}

# Function to verify deployment
verify_deployment() {
    print_step "3" "Verifying deployment..."
    
    # Check if services are running
    local check_commands="
        cd $VM_PROJECT_DIR && \
        docker compose ps --filter 'status=running' | grep -q 'Up' && \
        echo '✅ All services are running'
    "
    
    if run_ssh "$check_commands" "Service verification"; then
        print_success "All services verified and running"
    else
        print_warning "Some services may not be running properly"
        # Get logs for debugging
        run_ssh "cd $VM_PROJECT_DIR && docker compose logs --tail=20" "Recent logs"
    fi
}

# Function to show deployment summary
show_summary() {
    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}                     VM DEPLOYMENT SUMMARY                     ${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    
    print_success "🎉 Iris services deployed to VM successfully!"
    print_info "🌐 VM Details:"
    print_info "  - Host: $VM_HOST"
    print_info "  - User: $VM_USER"
    print_info "  - Project Directory: $VM_PROJECT_DIR"
    
    # Get external IP and port info
    print_info "🔗 Access Information:"
    print_info "  - SSH: ssh -i $SSH_KEY_PATH $VM_USER@$VM_HOST"
    print_info "  - HTTP: http://$VM_HOST:3000 (if firewall allows)"
    
    print_info "📝 Deployment log: $LOG_FILE"
    
    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
}

# Function to cleanup old logs
cleanup_logs() {
    if [ -d "$LOG_DIR" ]; then
        print_info "Cleaning up old deployment logs..."
        cd "$LOG_DIR"
        ls -t vm-deploy-*.log 2>/dev/null | tail -n +$((MAX_LOG_FILES + 1)) | xargs rm -f 2>/dev/null || true
        print_success "Log cleanup completed"
    fi
}

# Main deployment function
main() {
    print_status "🚀 Starting Iris VM auto-deployment..."
    print_info "🎯 Target VM: $VM_USER@$VM_HOST:$VM_PORT"
    print_info "📁 Local project: $LOCAL_PROJECT_DIR"
    print_info "📁 VM project: $VM_PROJECT_DIR"
    print_info "📝 Log file: $LOG_FILE"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    cleanup_logs
    
    # Check configuration
    if [ "$VM_USER" = "your-username" ] || [ "$VM_HOST" = "your-vm-ip" ]; then
        print_error "Please configure VM_USER and VM_HOST in the script!"
        print_info "Edit the configuration section at the top of this script"
        exit 1
    fi
    
    # Check SSH connection
    if ! check_ssh_connection; then
        exit 1
    fi
    
    # Sync code to VM
    if ! sync_code_to_vm; then
        exit 1
    fi
    
    # Deploy on VM
    if ! deploy_on_vm; then
        exit 1
    fi
    
    # Verify deployment
    verify_deployment
    
    # Show summary
    show_summary
    
    print_success "✨ VM deployment completed successfully!"
}

# Trap to handle script interruption
trap 'print_error "VM deployment interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"
