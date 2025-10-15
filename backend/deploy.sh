#!/bin/bash

# AWS EC2 Deployment Script for Go Backend
# Run this after launching an EC2 instance

echo "=== Starting Go Backend Deployment ==="

# Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Go
echo "Installing Go 1.23..."
cd ~
wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin
source ~/.bashrc

# Verify Go installation
go version

# Install Git
echo "Installing Git..."
sudo apt install git -y

# Clone or create project directory
echo "Setting up project directory..."
mkdir -p ~/go-backend
cd ~/go-backend

# You'll need to copy your files here or clone from git
echo "Copy your backend files to ~/go-backend/"
echo "Or clone from git: git clone your-repo-url ."

echo ""
echo "=== Next Steps ==="
echo "1. Copy your backend files to ~/go-backend/"
echo "2. Create .env file with your credentials"
echo "3. Run: go mod download"
echo "4. Run: go build -o app"
echo "5. Run: ./setup-service.sh to create systemd service"
