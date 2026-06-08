#!/bin/bash
set -e

echo "========================================="
echo "  Fashion Hub CRM — EC2 Deploy Script"
echo "========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}[1/7] Installing Node.js 20...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo -e "${GREEN}[1/7] Node.js $(node -v) found${NC}"
fi

# Check PM2
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}[2/7] Installing PM2...${NC}"
    sudo npm install -g pm2
    pm2 startup systemd -u "$USER" --hp "$HOME" || true
else
    echo -e "${GREEN}[2/7] PM2 found${NC}"
fi

# Check Nginx
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}[3/7] Installing Nginx...${NC}"
    sudo apt-get install -y nginx
else
    echo -e "${GREEN}[3/7] Nginx found${NC}"
fi

# Install dependencies
echo -e "${YELLOW}[4/7] Installing backend dependencies...${NC}"
cd backend && npm install --production && cd ..

echo -e "${YELLOW}[5/7] Installing frontend dependencies & building...${NC}"
cd frontend && npm install && npm run build && cd ..

# Copy .env files if .env.example exists but .env doesn't
if [ ! -f backend/.env ] && [ -f backend/.env.example ]; then
    echo -e "${YELLOW}[!] backend/.env not found. Copying from .env.example...${NC}"
    cp backend/.env.example backend/.env
    echo -e "${RED}[!] IMPORTANT: Edit backend/.env with your real values before starting!${NC}"
fi

if [ ! -f frontend/.env.local ] && [ -f frontend/.env.example ]; then
    echo -e "${YELLOW}[!] frontend/.env.local not found. Copying from .env.example...${NC}"
    cp frontend/.env.example frontend/.env.local
fi

# Configure Nginx
echo -e "${YELLOW}[6/7] Configuring Nginx...${NC}"
sudo cp nginx.conf /etc/nginx/sites-available/crm
sudo ln -sf /etc/nginx/sites-available/crm /etc/nginx/sites-enabled/crm
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# Create logs directory
sudo mkdir -p /var/log/crm

# Start with PM2
echo -e "${YELLOW}[7/7] Starting services with PM2...${NC}"
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save

echo ""
echo -e "${GREEN}========================================="
echo "  Deployment Complete!"
echo "========================================="
echo ""
EC2_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "YOUR_EC2_IP")
echo -e "  Frontend:  http://${EC2_IP}"
echo -e "  Backend:   http://${EC2_IP}/api/health"
echo ""
echo -e "  Useful commands:"
echo -e "    pm2 logs              # View logs"
echo -e "    pm2 status            # Check status"
echo -e "    pm2 restart all       # Restart services"
echo -e "    sudo systemctl reload nginx  # Reload Nginx"
echo ""
