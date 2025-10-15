# Manual Step-by-Step Deployment Guide
# Use these commands one by one if the automated script fails

$EC2_IP = "3.110.156.180"
$KEY_PATH = "c:\Users\aashi\Downloads\hello-world.pem"

Write-Host "=== Manual Deployment Commands ===" -ForegroundColor Green

Write-Host "`n1. Test SSH Connection:" -ForegroundColor Cyan
Write-Host "ssh -i `"$KEY_PATH`" ubuntu@$EC2_IP"

Write-Host "`n2. Upload Backend Files:" -ForegroundColor Cyan
Write-Host "scp -i `"$KEY_PATH`" -r F:\zzzz\go-project-practice\backend\* ubuntu@${EC2_IP}:~/go-backend/"

Write-Host "`n3. SSH into Server:" -ForegroundColor Cyan
Write-Host "ssh -i `"$KEY_PATH`" ubuntu@$EC2_IP"

Write-Host "`n4. Once inside EC2, run these commands:" -ForegroundColor Yellow
Write-Host @"

# Update system
sudo apt update && sudo apt upgrade -y

# Install Go
wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
echo 'export PATH=`$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Go to project directory
cd ~/go-backend

# Create .env file with your credentials
nano .env

# Add these lines to .env:
# MONGO_URI=your_mongodb_uri
# DB_NAME=project11
# CLOUDINARY_CLOUD_NAME=your_cloud_name
# CLOUDINARY_API_KEY=your_api_key
# CLOUDINARY_API_SECRET=your_api_secret
# JWT_SECRET=your_jwt_secret
# ADMIN_USER=admin
# ADMIN_PASS=your_password
# PORT=8080

# Save and exit (Ctrl+X, Y, Enter)

# Build and run
go mod download
go build -o app

# Test run (Ctrl+C to stop)
./app

# If it works, setup as service:
chmod +x setup-service.sh
./setup-service.sh

"@ -ForegroundColor White

Write-Host "`n5. Check if running:" -ForegroundColor Cyan
Write-Host "curl http://$EC2_IP:8080/api/blogs"

Write-Host "`n6. View logs (from SSH):" -ForegroundColor Cyan
Write-Host "sudo journalctl -u go-backend -f"
