#!/bin/bash

# Setup systemd service for Go backend

echo "=== Setting up systemd service ==="

# Create systemd service file
sudo tee /etc/systemd/system/go-backend.service > /dev/null <<EOF
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

# Security settings
NoNewPrivileges=true
PrivateTmp=true

# Logging
StandardOutput=append:/var/log/go-backend.log
StandardError=append:/var/log/go-backend-error.log

[Install]
WantedBy=multi-user.target
EOF

# Create log files
sudo touch /var/log/go-backend.log
sudo touch /var/log/go-backend-error.log
sudo chown $USER:$USER /var/log/go-backend.log
sudo chown $USER:$USER /var/log/go-backend-error.log

# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable go-backend

# Start the service
sudo systemctl start go-backend

# Check status
sudo systemctl status go-backend

echo ""
echo "=== Service Commands ==="
echo "Start:   sudo systemctl start go-backend"
echo "Stop:    sudo systemctl stop go-backend"
echo "Restart: sudo systemctl restart go-backend"
echo "Status:  sudo systemctl status go-backend"
echo "Logs:    sudo journalctl -u go-backend -f"
echo ""
echo "Application logs:"
echo "tail -f /var/log/go-backend.log"
echo "tail -f /var/log/go-backend-error.log"
