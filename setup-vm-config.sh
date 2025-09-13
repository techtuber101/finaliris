#!/bin/bash

# VM Configuration Setup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_status "🔧 Setting up VM configuration for Iris deployment..."

# Configuration file
CONFIG_FILE="vm-config.env"

print_info "This script will help you configure your Google VM connection details."

# Function to get user input with default
get_input() {
    local prompt="$1"
    local default="$2"
    local value
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " value
        echo "${value:-$default}"
    else
        read -p "$prompt: " value
        echo "$value"
    fi
}

# Function to validate IP address
validate_ip() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

echo ""
print_info "📋 Let's configure your Google VM connection:"
echo ""

# Get VM details
VM_USER=$(get_input "Enter your VM username" "ubuntu")
VM_HOST=$(get_input "Enter your VM external IP address" "")

# Validate IP
while ! validate_ip "$VM_HOST"; do
    print_warning "Invalid IP address format. Please enter a valid IP (e.g., 34.123.45.67)"
    VM_HOST=$(get_input "Enter your VM external IP address" "")
done

VM_PORT=$(get_input "Enter SSH port" "22")
VM_PROJECT_DIR="/home/$VM_USER/finaliris"

# SSH Key configuration
echo ""
print_info "🔑 SSH Key Configuration:"

# Check for existing SSH keys
if [ -f "$HOME/.ssh/id_rsa" ]; then
    SSH_KEY_PATH="$HOME/.ssh/id_rsa"
    print_info "Found existing SSH key: $SSH_KEY_PATH"
    use_existing=$(get_input "Use existing key? (y/n)" "y")
    
    if [[ "$use_existing" =~ ^[Yy]$ ]]; then
        print_success "Using existing SSH key"
    else
        SSH_KEY_PATH=$(get_input "Enter path to your SSH private key" "$HOME/.ssh/id_rsa")
    fi
else
    SSH_KEY_PATH=$(get_input "Enter path to your SSH private key" "$HOME/.ssh/id_rsa")
fi

# Verify SSH key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    print_warning "SSH key not found at $SSH_KEY_PATH"
    print_info "You can generate one with: ssh-keygen -t rsa -b 4096"
    print_info "Or copy your existing key to that location"
fi

# Test SSH connection
echo ""
print_info "🧪 Testing SSH connection..."
print_info "Attempting to connect to $VM_USER@$VM_HOST:$VM_PORT"

if ssh -i "$SSH_KEY_PATH" -p "$VM_PORT" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VM_USER@$VM_HOST" "echo 'Connection successful'" 2>/dev/null; then
    print_success "SSH connection test successful!"
else
    print_warning "SSH connection test failed. Please check:"
    print_info "  - VM IP address is correct"
    print_info "  - VM is running"
    print_info "  - SSH key is correct"
    print_info "  - Firewall allows SSH (port $VM_PORT)"
    print_info "  - VM has your public key in ~/.ssh/authorized_keys"
    echo ""
    continue_setup=$(get_input "Continue with setup anyway? (y/n)" "y")
    if [[ ! "$continue_setup" =~ ^[Yy]$ ]]; then
        print_info "Setup cancelled. Please fix SSH connection and try again."
        exit 1
    fi
fi

# Create configuration file
echo ""
print_info "💾 Creating configuration file..."

cat > "$CONFIG_FILE" << EOF
# VM Configuration for Iris Deployment
# Generated on $(date)

# VM Connection Details
VM_USER="$VM_USER"
VM_HOST="$VM_HOST"
VM_PORT="$VM_PORT"
SSH_KEY_PATH="$SSH_KEY_PATH"
VM_PROJECT_DIR="$VM_PROJECT_DIR"

# Local Project Directory
LOCAL_PROJECT_DIR="/Users/ishaantheman/theirispanaroma"
EOF

print_success "Configuration saved to $CONFIG_FILE"

# Update vm-deploy.sh with configuration
echo ""
print_info "🔧 Updating deployment script with your configuration..."

# Create a backup of the original script
cp vm-deploy.sh vm-deploy.sh.backup

# Update the configuration section in vm-deploy.sh
sed -i.bak "
s/VM_USER=\"your-username\"/VM_USER=\"$VM_USER\"/
s/VM_HOST=\"your-vm-ip\"/VM_HOST=\"$VM_HOST\"/
s/VM_PORT=\"22\"/VM_PORT=\"$VM_PORT\"/
s|SSH_KEY_PATH=\"\$HOME/.ssh/id_rsa\"|SSH_KEY_PATH=\"$SSH_KEY_PATH\"|
s|VM_PROJECT_DIR=\"/home/\$VM_USER/finaliris\"|VM_PROJECT_DIR=\"$VM_PROJECT_DIR\"|
" vm-deploy.sh

rm vm-deploy.sh.bak

print_success "Deployment script updated with your configuration"

# Show next steps
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                     CONFIGURATION COMPLETE                     ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

print_success "🎉 VM configuration completed successfully!"
print_info "📋 Configuration Summary:"
print_info "  - VM User: $VM_USER"
print_info "  - VM Host: $VM_HOST"
print_info "  - SSH Port: $VM_PORT"
print_info "  - SSH Key: $SSH_KEY_PATH"
print_info "  - VM Project Dir: $VM_PROJECT_DIR"

echo ""
print_info "📋 Next Steps:"
print_info "  1. Test deployment: ./vm-deploy.sh"
print_info "  2. Set up Git hooks for auto-deployment: ./setup-vm-git-hooks.sh"
print_info "  3. Make a commit and push to trigger VM deployment"

echo ""
print_info "🔧 Useful Commands:"
print_info "  - Manual deployment: ./vm-deploy.sh"
print_info "  - SSH to VM: ssh -i $SSH_KEY_PATH $VM_USER@$VM_HOST"
print_info "  - View VM logs: ssh -i $SSH_KEY_PATH $VM_USER@$VM_HOST 'cd $VM_PROJECT_DIR && docker compose logs'"

echo ""
print_warning "⚠️  Important Notes:"
print_info "  - Make sure your VM has Docker and Docker Compose installed"
print_info "  - Ensure firewall allows HTTP traffic on port 3000"
print_info "  - Your SSH public key should be in ~/.ssh/authorized_keys on the VM"

print_success "✨ Setup completed!"
