# AWS EC2 Deployment - Step by Step Guide

## Prerequisites
- AWS Account
- AWS CLI configured with credentials

## Step 1: Launch EC2 Instance

### Option A: Using AWS Console
1. Go to AWS Console → EC2
2. Click "Launch Instance"
3. Choose **Ubuntu Server 22.04 LTS**
4. Instance type: **t2.micro** (free tier eligible)
5. Create or select a key pair (download .pem file)
6. Configure Security Group:
   - SSH (22) - Your IP
   - Custom TCP (8080) - 0.0.0.0/0 (or your frontend IP)
7. Launch instance

### Option B: Using AWS CLI

```bash
# Create key pair
aws ec2 create-key-pair --key-name go-backend-key --query 'KeyMaterial' --output text > go-backend-key.pem
chmod 400 go-backend-key.pem

# Create security group
aws ec2 create-security-group --group-name go-backend-sg --description "Security group for Go backend"

# Add SSH rule
aws ec2 authorize-security-group-ingress --group-name go-backend-sg --protocol tcp --port 22 --cidr 0.0.0.0/0

# Add application port rule
aws ec2 authorize-security-group-ingress --group-name go-backend-sg --protocol tcp --port 8080 --cidr 0.0.0.0/0

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --count 1 \
  --instance-type t2.micro \
  --key-name go-backend-key \
  --security-groups go-backend-sg \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=go-backend}]'
```

## Step 2: Connect to EC2 Instance

```bash
# Get instance public IP
aws ec2 describe-instances --filters "Name=tag:Name,Values=go-backend" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# SSH into instance
ssh -i go-backend-key.pem ubuntu@YOUR_INSTANCE_IP
```

## Step 3: Setup Server

Once connected to EC2:

```bash
# Download and run deployment script
wget https://raw.githubusercontent.com/your-repo/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

Or manually:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Go
wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Create project directory
mkdir -p ~/go-backend
cd ~/go-backend
```

## Step 4: Upload Your Code

### Option A: Using SCP from your local machine

```powershell
# From your Windows machine
scp -i go-backend-key.pem -r F:\zzzz\go-project-practice\backend/* ubuntu@YOUR_INSTANCE_IP:~/go-backend/
```

### Option B: Using Git

```bash
# On EC2 instance
cd ~/go-backend
git clone https://github.com/your-username/your-repo.git .
```

### Option C: Manual file transfer
Use FileZilla or WinSCP to transfer files

## Step 5: Configure Environment Variables

```bash
# On EC2 instance
cd ~/go-backend
nano .env
```

Add your credentials:
```
MONGO_URI=your_mongodb_uri
DB_NAME=project11
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
JWT_SECRET=your_jwt_secret
ADMIN_USER=admin
ADMIN_PASS=your_password
PORT=8080
```

Save and exit (Ctrl+X, Y, Enter)

## Step 6: Build and Test

```bash
# Install dependencies
go mod download

# Build the application
go build -o app

# Test run (Ctrl+C to stop)
./app
```

## Step 7: Setup as System Service

```bash
# Make setup script executable
chmod +x setup-service.sh

# Run setup script
./setup-service.sh
```

## Step 8: Verify Deployment

```bash
# Check service status
sudo systemctl status go-backend

# View logs
tail -f /var/log/go-backend.log

# Test API
curl http://localhost:8080/api/blogs
```

## Step 9: Test from Outside

From your local machine:
```powershell
curl http://YOUR_INSTANCE_IP:8080/api/blogs
```

## Step 10: Update Frontend

Update your frontend `.env`:
```
NEXT_PUBLIC_API_URL=http://YOUR_INSTANCE_IP:8080/api
```

## Common Issues & Solutions

### Issue: Port already in use
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
sudo systemctl restart go-backend
```

### Issue: Service won't start
```bash
sudo journalctl -u go-backend -n 50
# Check error logs
tail -f /var/log/go-backend-error.log
```

### Issue: Permission denied
```bash
chmod +x app
chmod 644 .env
```

## Useful Commands

```bash
# Service management
sudo systemctl start go-backend
sudo systemctl stop go-backend
sudo systemctl restart go-backend
sudo systemctl status go-backend

# View logs
sudo journalctl -u go-backend -f
tail -f /var/log/go-backend.log

# Update code
cd ~/go-backend
git pull
go build -o app
sudo systemctl restart go-backend

# Check if port is open
sudo netstat -tlnp | grep 8080
```

## Optional: Setup HTTPS with Nginx

```bash
# Install Nginx
sudo apt install nginx -y

# Configure Nginx as reverse proxy
sudo nano /etc/nginx/sites-available/go-backend

# Add configuration:
server {
    listen 80;
    server_name your_domain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# Enable site
sudo ln -s /etc/nginx/sites-available/go-backend /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Install SSL with Let's Encrypt
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your_domain.com
```

## Cost Optimization

- Use **t2.micro** (free tier: 750 hours/month for 12 months)
- Stop instance when not in use
- Use Elastic IP to keep same IP address
- Consider AWS Lambda for lower costs if traffic is low

## Monitoring

```bash
# Install htop for system monitoring
sudo apt install htop -y
htop

# Check disk usage
df -h

# Check memory usage
free -h
```
