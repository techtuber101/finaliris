#!/bin/bash

# Setup script for Git hooks to auto-deploy Iris to VM on push

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

# Configuration
CURRENT_DIR="/Users/ishaantheman/theirispanaroma"
VM_DEPLOY_SCRIPT="$CURRENT_DIR/vm-deploy.sh"
HOOKS_DIR="$CURRENT_DIR/.git/hooks"

print_status "🔧 Setting up Git hooks for VM auto-deployment..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "Not in a Git repository. Please run this from the project root."
    exit 1
fi

# Check if VM deploy script exists
if [ ! -f "$VM_DEPLOY_SCRIPT" ]; then
    print_error "VM deploy script not found: $VM_DEPLOY_SCRIPT"
    print_info "Please run ./setup-vm-config.sh first to configure VM deployment"
    exit 1
fi

# Check if VM deploy script is executable
if [ ! -x "$VM_DEPLOY_SCRIPT" ]; then
    print_error "VM deploy script is not executable: $VM_DEPLOY_SCRIPT"
    print_info "Making it executable..."
    chmod +x "$VM_DEPLOY_SCRIPT"
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Remove existing local deployment hooks (if any)
if [ -f "$HOOKS_DIR/post-commit" ]; then
    print_info "Removing existing local deployment hooks..."
    rm "$HOOKS_DIR/post-commit"
fi

if [ -f "$HOOKS_DIR/post-push" ]; then
    print_info "Removing existing local deployment hooks..."
    rm "$HOOKS_DIR/post-push"
fi

# Create VM deployment hooks

# Post-commit hook (triggers after each commit)
cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash

# Post-commit hook for VM auto-deployment
echo "🔄 Commit detected, triggering VM deployment..."

# Get the VM deployment script path
SCRIPT_DIR="/Users/ishaantheman/theirispanaroma"
VM_DEPLOY_SCRIPT="$SCRIPT_DIR/vm-deploy.sh"

# Check if VM deploy script exists and is executable
if [ -f "$VM_DEPLOY_SCRIPT" ] && [ -x "$VM_DEPLOY_SCRIPT" ]; then
    echo "🚀 Starting VM deployment..."
    exec "$VM_DEPLOY_SCRIPT"
else
    echo "❌ VM deploy script not found or not executable: $VM_DEPLOY_SCRIPT"
    echo "💡 Run ./setup-vm-config.sh to configure VM deployment"
    exit 1
fi
EOF

# Post-push hook (triggers after each push)
cat > "$HOOKS_DIR/post-push" << 'EOF'
#!/bin/bash

# Post-push hook for VM auto-deployment
echo "🔄 Git push completed, triggering VM deployment..."

# Get the VM deployment script path
SCRIPT_DIR="/Users/ishaantheman/theirispanaroma"
VM_DEPLOY_SCRIPT="$SCRIPT_DIR/vm-deploy.sh"

# Check if VM deploy script exists and is executable
if [ -f "$VM_DEPLOY_SCRIPT" ] && [ -x "$VM_DEPLOY_SCRIPT" ]; then
    echo "🚀 Starting VM deployment..."
    exec "$VM_DEPLOY_SCRIPT"
else
    echo "❌ VM deploy script not found or not executable: $VM_DEPLOY_SCRIPT"
    echo "💡 Run ./setup-vm-config.sh to configure VM deployment"
    exit 1
fi
EOF

# Post-receive hook (for server-side repositories)
cat > "$HOOKS_DIR/post-receive" << 'EOF'
#!/bin/bash

# Post-receive hook for VM auto-deployment
echo "🔄 Git push received, triggering VM deployment..."

# Get the VM deployment script path
SCRIPT_DIR="/Users/ishaantheman/theirispanaroma"
VM_DEPLOY_SCRIPT="$SCRIPT_DIR/vm-deploy.sh"

# Check if VM deploy script exists and is executable
if [ -f "$VM_DEPLOY_SCRIPT" ] && [ -x "$VM_DEPLOY_SCRIPT" ]; then
    echo "🚀 Starting VM deployment..."
    exec "$VM_DEPLOY_SCRIPT"
else
    echo "❌ VM deploy script not found or not executable: $VM_DEPLOY_SCRIPT"
    exit 1
fi
EOF

# Make hooks executable
chmod +x "$HOOKS_DIR/post-commit"
chmod +x "$HOOKS_DIR/post-push"
chmod +x "$HOOKS_DIR/post-receive"

print_success "Git hooks created successfully!"

print_info "📋 VM Deployment Hooks:"
print_info "  - post-commit: Triggers VM deployment after each commit"
print_info "  - post-push: Triggers VM deployment after each push"
print_info "  - post-receive: For server-side repositories"

print_info "💡 To test VM deployment manually:"
print_info "  ./vm-deploy.sh"

print_info "🔧 To disable auto-deployment, remove the hook files:"
print_info "  rm .git/hooks/post-commit .git/hooks/post-push .git/hooks/post-receive"

print_success "✨ VM Git hooks setup completed!"

echo ""
print_info "🎯 What happens now:"
print_info "  - Every commit/push will automatically deploy to your Google VM"
print_info "  - Code will be synced via SSH/rsync"
print_info "  - Docker containers will be built and started on the VM"
print_info "  - You'll get real-time status updates"

print_info "🧪 Test it:"
print_info "  git add . && git commit -m 'Test VM deployment' && git push"
