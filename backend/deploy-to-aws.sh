#!/bin/bash

# AWS EC2 Deployment Script for Go Backend
# Run this from WSL

EC2_IP="3.110.156.180"
KEY_PATH="$HOME/hello-world.pem"
BACKEND_PATH="/mnt/f/zzzz/go-project-practice/backend"

echo "=== Deploying Go Backend to AWS EC2 ==="
echo "EC2 IP: $EC2_IP"

# Fix key permissions
echo -e "\n[0/6] Setting correct key permissions..."
chmod 600 "$KEY_PATH"

# Try to detect the correct username
echo -e "\n[1/6] Testing SSH connection..."
SSH_USER=""

for user in ubuntu ec2-user admin root; do
    echo "Trying username: $user"
    if ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes $user@$EC2_IP "echo 'Success'" 2>/dev/null; then
        SSH_USER=$user
        echo "Found working username: $SSH_USER"
        break
    fi
done

if [ -z "$SSH_USER" ]; then
    echo "Error: Cannot connect to EC2 instance with any common username."
    echo "Please try manually: ssh -i $KEY_PATH ubuntu@$EC2_IP"
    echo "Or check AWS console for the correct AMI username."
    exit 1
fi

echo "Connection successful with user: $SSH_USER"

# Update all commands to use the correct username
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no $SSH_USER@$EC2_IP "echo 'Connection verified!'"

if [ $? -ne 0 ]; then
    echo "Error: Cannot connect to EC2 instance. Check your key and IP."
    exit 1
fi

# Create directory on EC2
echo -e "\n[2/6] Creating project directory on EC2..."
ssh -i "$KEY_PATH" $SSH_USER@$EC2_IP "mkdir -p ~/go-backend"

# Upload backend files
echo -e "\n[3/6] Uploading backend files..."
scp -i "$KEY_PATH" -r "$BACKEND_PATH"/* $SSH_USER@$EC2_IP:~/go-backend/

if [ $? -ne 0 ]; then
    echo "Error uploading files."
    exit 1
fi

# Upload deployment scripts
echo -e "\n[4/6] Setting up Go environment..."
ssh -i "$KEY_PATH" $SSH_USER@$EC2_IP << 'EOF'
cd ~/go-backend

# Update system
echo "Updating system packages..."
sudo apt update -y

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Installing Go 1.23..."
    wget -q https://go.dev/dl/go1.23.0.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
else
    echo "Go is already installed: $(go version)"
    export PATH=$PATH:/usr/local/go/bin
fi

# Make scripts executable
chmod +x deploy.sh setup-service.sh 2>/dev/null || true
EOF

# Build application
echo -e "\n[5/6] Building Go application..."
ssh -i "$KEY_PATH" $SSH_USER@$EC2_IP << 'EOF'
cd ~/go-backend
export PATH=$PATH:/usr/local/go/bin

echo "Downloading Go modules..."
go mod download

echo "Building application..."
go build -o app

if [ ! -f "./app" ]; then
    echo "Error: Build failed!"
    exit 1
fi

echo "Build successful!"
EOF

# Setup systemd service
echo -e "\n[6/6] Setting up systemd service..."
ssh -i "$KEY_PATH" $SSH_USER@$EC2_IP << 'EOF'
cd ~/go-backend

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "WARNING: .env file not found!"
    echo "Please create .env file with your credentials:"
    echo "  ssh -i <key> ubuntu@3.110.156.180"
    echo "  cd ~/go-backend"
    echo "  nano .env"
    echo ""
    echo "Add these variables:"
    echo "  MONGO_URI=your_mongodb_uri"
    echo "  DB_NAME=project11"
    echo "  CLOUDINARY_CLOUD_NAME=your_cloud_name"
    echo "  CLOUDINARY_API_KEY=your_api_key"
    echo "  CLOUDINARY_API_SECRET=your_api_secret"
    echo "  JWT_SECRET=your_jwt_secret"
    echo "  ADMIN_USER=admin"
    echo "  ADMIN_PASS=your_password"
    echo "  PORT=8080"
    exit 0
fi

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/go-backend.service > /dev/null <<EOFSERVICE
[Unit]
Description=Go Backend API Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/go-backend
ExecStart=$HOME/go-backend/app
Restart=always
RestartSec=10
EnvironmentFile=$HOME/go-backend/.env

StandardOutput=append:/var/log/go-backend.log
StandardError=append:/var/log/go-backend-error.log

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Create log files
sudo touch /var/log/go-backend.log /var/log/go-backend-error.log
sudo chown $USER:$USER /var/log/go-backend.log /var/log/go-backend-error.log

# Reload and start service
sudo systemctl daemon-reload
sudo systemctl enable go-backend
sudo systemctl restart go-backend

# Check status
sleep 2
sudo systemctl status go-backend --no-pager
EOF

echo -e "\n=== Deployment Complete! ==="
echo ""
echo "Your backend should be running at: http://$EC2_IP:8080"
echo ""
echo "Test it with:"
echo "  curl http://$EC2_IP:8080/api/blogs"
echo ""
echo "SSH into server:"
echo "  ssh -i \"$KEY_PATH\" $SSH_USER@$EC2_IP"
echo ""
echo "View logs:"
echo "  ssh -i \"$KEY_PATH\" $SSH_USER@$EC2_IP 'sudo journalctl -u go-backend -f'"
echo ""
echo "Service commands:"
echo "  sudo systemctl status go-backend"
echo "  sudo systemctl restart go-backend"
echo "  sudo systemctl stop go-backend"
echo ""
echo "Update frontend .env with:"
echo "  NEXT_PUBLIC_API_URL=http://$EC2_IP:8080/api"
