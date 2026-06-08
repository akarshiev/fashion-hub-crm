# AWS EC2 Deployment Guide

This guide walks you through deploying Fashion Hub CRM on an AWS EC2 instance.

## Prerequisites

- AWS account with EC2 access
- An EC2 instance (Ubuntu 22.04+ recommended, `t2.micro` or larger)
- Security Group allowing inbound: **22 (SSH)**, **80 (HTTP)**, **443 (HTTPS)**
- MongoDB Atlas account (free tier works) or local MongoDB on the instance
- GitHub repository with Actions enabled (for CI/CD)

## Step 1: Connect to EC2

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

## Step 2: Clone the Project

```bash
git clone https://github.com/YOUR_USERNAME/fashion-hub-crm.git
cd fashion-hub-crm
```

## Step 3: Configure Environment Variables

### Backend
```bash
cp backend/.env.example backend/.env
nano backend/.env
```

Update the following:
```env
# If using MongoDB Atlas:
MONGODB_URI=mongodb+srv://USER:PASS@cluster.mongodb.net/crm-system

# If using local MongoDB:
MONGODB_URI=mongodb://localhost:27017/crm-system

# IMPORTANT: Change this to a strong random string!
JWT_SECRET=your-very-long-random-secret-here

# Set your EC2 public IP or domain
FRONTEND_URL=http://YOUR_EC2_PUBLIC_IP
```

### Frontend
```bash
cp frontend/.env.example frontend/.env.local
nano frontend/.env.local
```

Update:
```env
NEXT_PUBLIC_API_URL=http://YOUR_EC2_PUBLIC_IP
```

## Step 4: Run Deploy Script

```bash
chmod +x deploy.sh
./deploy.sh
```

This will:
1. Install Node.js 20 (if not present)
2. Install PM2 (if not present)
3. Install Nginx (if not present)
4. Install all dependencies
5. Build the frontend
6. Configure Nginx as reverse proxy
7. Start services with PM2

## Step 5: Seed the Database

```bash
cd backend && npm run seed && cd ..
```

## Step 6: Test

```bash
# Health check
curl http://localhost:5000/api/health

# Frontend
curl -I http://localhost
```

Open `http://YOUR_EC2_PUBLIC_IP` in your browser.

## Login Credentials

| Role    | Email              | Password    |
|---------|--------------------|-------------|
| Admin   | admin@example.com  | admin123    |
| Customer| john@company1.com  | password123 |

## GitHub Actions CI/CD Setup

The project includes a GitHub Actions workflow (`.github/workflows/deploy.yml`) that automatically deploys to EC2 on every push to `main`.

### Required GitHub Secrets

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret** and add:

| Secret Name       | Value                                        |
|-------------------|----------------------------------------------|
| `EC2_HOST`        | Your EC2 public IP (e.g., `54.123.45.67`)    |
| `EC2_USERNAME`    | SSH username (usually `ubuntu`)              |
| `EC2_SSH_KEY`     | Contents of your `.pem` private key file     |
| `EC2_PROJECT_DIR` | Full path to project on EC2 (e.g., `/home/ubuntu/fashion-hub-crm`) |

### To set up the SSH key secret:

```bash
# Copy your .pem key content
cat your-key.pem
# Copy the entire output and paste it as the EC2_SSH_KEY secret value
```

### How it works

1. Push to `main` branch
2. GitHub Actions SSHs into your EC2
3. Pulls latest code
4. Installs dependencies & builds frontend
5. Restarts PM2 services

### First deploy

On first deploy, PM2 will start the services. On subsequent deploys, it will restart them.

## Useful PM2 Commands

```bash
pm2 status                 # Check running processes
pm2 logs                   # View real-time logs
pm2 logs crm-backend       # Backend logs only
pm2 logs crm-frontend      # Frontend logs only
pm2 restart all            # Restart all services
pm2 stop all               # Stop all services
pm2 delete all             # Remove all from PM2
pm2 save                   # Save current process list
pm2 startup                # Auto-start on reboot
```

## HTTPS Setup (Recommended)

For production, use Let's Encrypt with Certbot:

```bash
# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get SSL certificate (replace YOUR_DOMAIN)
sudo certbot --nginx -d YOUR_DOMAIN -d www.YOUR_DOMAIN

# Auto-renewal is set up automatically. Test with:
sudo certbot renew --dry-run
```

## MongoDB Atlas Setup (Free Tier)

1. Go to https://cloud.mongodb.com
2. Create a free account
3. Create a M0 cluster
4. Create a database user (Database Access)
5. Add your EC2 IP to the whitelist (Network Access → IP Access List)
6. Get the connection string and paste it into `backend/.env`

## Troubleshooting

### Services not starting
```bash
pm2 logs                   # Check error logs
pm2 status                 # Check process status
```

### Port 80 already in use
```bash
sudo lsof -ti:80 | xargs kill -9
sudo systemctl restart nginx
```

### MongoDB connection refused
- Check if your EC2 IP is whitelisted in MongoDB Atlas
- Verify connection string in `backend/.env`
- Test: `curl http://localhost:5000/api/health`

### Frontend shows blank page
- Check `NEXT_PUBLIC_API_URL` in `frontend/.env.local`
- Ensure frontend was built: `cd frontend && npm run build`
- Check PM2 logs: `pm2 logs crm-frontend`
