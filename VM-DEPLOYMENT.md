# Iris VM Auto-Deployment

This setup provides automatic deployment of your Iris project to your Google VM whenever you push commits to your Git repository.

## 📁 VM Deployment Files

### 1. `vm-deploy.sh`
Main VM deployment script that:
- Syncs code to VM via SSH/rsync
- Builds Docker containers on VM
- Stops and starts Iris services
- Provides comprehensive status updates

### 2. `setup-vm-config.sh`
Interactive configuration script to set up:
- VM connection details (IP, username, SSH key)
- Tests SSH connectivity
- Updates deployment script with your settings

### 3. `setup-vm-git-hooks.sh`
Sets up Git hooks for automatic VM deployment on:
- `git commit` (post-commit hook)
- `git push` (post-push hook)

## 🚀 Quick Setup

### Step 1: Configure VM Connection
```bash
./setup-vm-config.sh
```
This will ask for:
- Your VM username (e.g., `ubuntu`, `your-username`)
- Your VM external IP address
- SSH port (usually `22`)
- Path to your SSH private key

### Step 2: Set Up Git Hooks
```bash
./setup-vm-git-hooks.sh
```

### Step 3: Test Deployment
```bash
# Manual test
./vm-deploy.sh

# Or make a test commit
git add .
git commit -m "Test VM deployment"
git push
```

## 🔧 VM Requirements

Your Google VM needs:

1. **Docker and Docker Compose** installed
2. **SSH access** with your public key in `~/.ssh/authorized_keys`
3. **Firewall rules** allowing:
   - SSH (port 22)
   - HTTP (port 3000) for Iris access
4. **User permissions** to run Docker commands

## 📊 What Happens During Deployment

1. **Sync Code**: Rsync your local project to VM
2. **Build**: `docker compose build --no-cache` on VM
3. **Stop**: `docker compose down` on VM
4. **Start**: `docker compose up -d` on VM
5. **Verify**: Check service health and status

## 🎯 Status Updates

You'll see real-time updates like:
```
🚀 Starting Iris VM auto-deployment...
🎯 Target VM: ubuntu@34.123.45.67:22
🔄 [1] Syncing code to VM...
✅ Code synced to VM successfully
🔄 [2] Deploying on VM...
✅ Deployment completed on VM
🔄 [3] Verifying deployment...
✅ All services verified and running
🎉 Iris services deployed to VM successfully!
🌐 Access: http://34.123.45.67:3000
```

## 🔍 Troubleshooting

### SSH Connection Issues
```bash
# Test SSH manually
ssh -i ~/.ssh/your-key ubuntu@your-vm-ip

# Check if VM is running
gcloud compute instances list

# Check firewall rules
gcloud compute firewall-rules list
```

### VM Setup Issues
```bash
# Install Docker on VM
ssh -i ~/.ssh/your-key ubuntu@your-vm-ip
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### View VM Logs
```bash
# SSH to VM and check logs
ssh -i ~/.ssh/your-key ubuntu@your-vm-ip
cd /home/ubuntu/finaliris
docker compose logs -f
```

## 🛠️ Manual Commands

### Deploy Manually
```bash
./vm-deploy.sh
```

### SSH to VM
```bash
ssh -i ~/.ssh/your-key ubuntu@your-vm-ip
```

### Check VM Status
```bash
ssh -i ~/.ssh/your-key ubuntu@your-vm-ip 'cd /home/ubuntu/finaliris && docker compose ps'
```

## 🔒 Security Notes

- Uses SSH key authentication (no passwords)
- Excludes sensitive files (.env, .git) from sync
- Runs with your user permissions on VM
- Includes comprehensive error handling

## 📝 Configuration

Edit `vm-deploy.sh` to modify:
- Target directory on VM
- Excluded files/folders
- Deployment commands
- Timeout values

## 🚫 Disable Auto-Deployment

```bash
# Remove Git hooks
rm .git/hooks/post-commit .git/hooks/post-push .git/hooks/post-receive
```

---

**Ready to deploy to your Google VM! 🚀**
