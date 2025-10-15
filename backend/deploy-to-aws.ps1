# AWS EC2 Deployment Script for Go Backend
# Run this from PowerShell

$EC2_IP = "3.110.156.180"
$KEY_PATH = "/mnt/c/Users/aashi/Downloads/hello-world.pem"
$BACKEND_PATH = "/mnt/f/zzzz/go-project-practice/backend"

Write-Host "=== Deploying Go Backend to AWS EC2 ===" -ForegroundColor Green
Write-Host "EC2 IP: $EC2_IP" -ForegroundColor Yellow

# Step 1: Upload backend files
Write-Host "`n[1/5] Uploading backend files..." -ForegroundColor Cyan
scp -i $KEY_PATH -r "$BACKEND_PATH\*" ubuntu@${EC2_IP}:~/go-backend/

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error uploading files. Please check your connection." -ForegroundColor Red
    exit 1
}

# Step 2: Upload deployment scripts
Write-Host "`n[2/5] Uploading deployment scripts..." -ForegroundColor Cyan
scp -i $KEY_PATH "$BACKEND_PATH\deploy.sh" ubuntu@${EC2_IP}:~/go-backend/
scp -i $KEY_PATH "$BACKEND_PATH\setup-service.sh" ubuntu@${EC2_IP}:~/go-backend/

# Step 3: Run initial setup
Write-Host "`n[3/5] Setting up Go on EC2..." -ForegroundColor Cyan
ssh -i $KEY_PATH ubuntu@${EC2_IP} @"
cd ~/go-backend
chmod +x deploy.sh setup-service.sh
./deploy.sh
"@

# Step 4: Build application
Write-Host "`n[4/5] Building Go application..." -ForegroundColor Cyan
ssh -i $KEY_PATH ubuntu@${EC2_IP} @"
cd ~/go-backend
go mod download
go build -o app
"@

# Step 5: Setup systemd service
Write-Host "`n[5/5] Setting up systemd service..." -ForegroundColor Cyan
ssh -i $KEY_PATH ubuntu@${EC2_IP} @"
cd ~/go-backend
./setup-service.sh
"@

Write-Host "`n=== Deployment Complete! ===" -ForegroundColor Green
Write-Host "`nYour backend is now running at: http://$EC2_IP:8080" -ForegroundColor Yellow
Write-Host "`nTest it with: curl http://$EC2_IP:8080/api/blogs" -ForegroundColor Cyan
Write-Host "`nSSH into server: ssh -i $KEY_PATH ubuntu@$EC2_IP" -ForegroundColor Cyan
Write-Host "`nView logs: ssh -i $KEY_PATH ubuntu@$EC2_IP 'sudo journalctl -u go-backend -f'" -ForegroundColor Cyan
