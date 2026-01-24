# Free VPS Comparison Guide for FutureProof Backend

**Date:** 2026-01-16
**Purpose:** Compare free VPS providers and recommend best option for FutureProof backend

---

## 🏆 Top Free VPS Providers Ranked

### Rank #1: Oracle Cloud Infrastructure (OCI) - Always Free ⭐⭐⭐⭐⭐

**Best For:** Production workloads, long-term free usage

**What You Get (Always Free):**
- **Compute:**
  - 2x AMD-based VMs: 1 OCPU, 1 GB RAM each
  - **OR** up to 4x Arm-based VMs (Ampere A1): 6 OCPUs, 24 GB RAM total
  - **Recommended:** 2x Arm VMs with 12 GB RAM each = 24 GB total!
- **Storage:**
  - 2x 200 GB Block Volume storage
- **Network:**
  - 10 TB/month outbound data transfer
  - Public IP addresses (free)
  - Load Balancer: 10 Mbps (free tier)
- **Database:**
  - 2x Autonomous DB: 20 GB each (Oracle Database)
  - OR run PostgreSQL/MySQL on compute VM (recommended)
- **Other:**
  - 10 GB Object Storage
  - 500 million monitoring datapoints
  - 10 GB logging ingestion

**Pros:**
✅ Most generous free tier by FAR
✅ 24 GB RAM (Arm-based) is incredible for free
✅ No time limit (forever free)
✅ 10 TB/month bandwidth (huge!)
✅ 400 GB storage (plenty)
✅ Production-ready

**Cons:**
❌ More complex setup than others
❌ Console UI can be confusing
❌ Account credit check required (may fail in some countries)
❌ Arm-based VMs require ARM64-compatible Docker images

**Setup Difficulty:** ⭐⭐⭐ (Medium)

**Best For:** Production backend, serious projects, long-term hosting

---

### Rank #2: Google Cloud Platform (GCP) - Free Trial ⭐⭐⭐⭐

**Best For:** Learning, testing, short-term projects

**What You Get (Free Trial - 3 Months):**
- **Credit:** $300 free credit for 90 days
- **Always Free (after trial):**
  - 1x f1-micro VM: 0.2 vCPU, 0.6 GB RAM (us-east1, us-west1, us-central1 only)
  - 1x small DB: 30 GB Cloud SQL (MySQL/PostgreSQL)
  - 5 GB/month outbound data (not 10 TB like OCI!)

**Pros:**
✅ Best console UI (most user-friendly)
✅ $300 credit = 3 months of any VM size
✅ Great documentation
✅ Always free micro instance (after trial)
✅ Excellent ecosystem

**Cons:**
❌ Free trial ends after 3 months
❌ Always-free micro instance is TOO SMALL (0.6 GB RAM)
❌ Only 5 GB/month bandwidth (vs 10 TB on OCI)
❌ Expensive after free trial

**Setup Difficulty:** ⭐ (Very Easy)

**Best For:** Learning GCP, testing, short-term projects (3 months)

---

### Rank #3: AWS Free Tier ⭐⭐⭐

**Best For:** Learning AWS, 12-month projects

**What You Get (12 Months):**
- **Compute:** 750 hours/month of t2.micro or t3.micro (1 vCPU, 1 GB RAM)
- **Storage:** 30 GB EBS storage
- **Data Transfer:** 100 GB/month outbound
- **Database:** 25 GB DynamoDB (NoSQL), 750 hours of RDB (t2.micro - MySQL/PostgreSQL/Oracle)

**After 12 Months:**
- Nothing free (except 1 million Lambda requests, 25 GB DynamoDB)

**Pros:**
✅ Most popular cloud provider
✅ 12 months free (good runway)
✅ Great documentation and community
✅ 1 GB RAM is usable (unlike GCP's 0.6 GB)

**Cons:**
❌ Free tier ends after 12 months
❌ Lock-in to AWS ecosystem
❌ Can get expensive quickly if you exceed limits
❌ Only 100 GB/month bandwidth
❌ 1 vCPU can be slow

**Setup Difficulty:** ⭐⭐ (Easy)

**Best For:** Learning AWS, medium-term projects (up to 12 months)

---

### Rank #4: Azure Free Tier ⭐⭐⭐

**Best For:** Microsoft ecosystem, Windows-based projects

**What You Get (12 Months):**
- **Credit:** $200 free credit for first 30 days
- **Free Services (12 months):**
  - 750 hours/month of B1s burstable VM (1 vCPU, 1 GB RAM)
  - 64 GB SSD storage
  - 100 GB/month outbound data transfer

**After 12 Months:**
- Nothing free (except some Azure services)

**Pros:**
✅ $200 credit for first month
✅ Good if you need Windows VM (rare for backend)
✅ integrates with Microsoft ecosystem

**Cons:**
❌ Free tier ends after 12 months
❌ Similar limitations to AWS
❌ Console UI can be slow
❌ More expensive than AWS after free tier

**Setup Difficulty:** ⭐⭐ (Easy)

**Best For:** Microsoft shops, Windows-based projects

---

### Rank #5: Railway.app ⭐⭐⭐⭐

**Best For:** Quick deployment, developer experience, hobby projects

**What You Get (Free Tier):**
- **Credit:** $5 free credit every month
- **Compute:** ~512 MB RAM, 0.2 vCPU (varies by usage)
- **Database:** PostgreSQL, MySQL, Redis, MongoDB (free tier)
- **Deployment:** Git push to deploy (CI/CD built-in)
- **Bandwidth:** 100 GB/month

**Pricing:** $5/month = 512 MB RAM, $20/month = 2 GB RAM, $50/month = 4 GB RAM

**Pros:**
✅ Easiest deployment (just git push)
✅ Built-in CI/CD
✅ Great DX (developer experience)
✅ Free databases included
✅ No credit card required to start

**Cons:**
❌ Very limited resources on free tier (512 MB RAM)
❌ Not suitable for production
❌ Gets expensive quickly ($20-50/month for more RAM)
❌ Less control than raw VPS

**Setup Difficulty:** ⭐ (Very Easy - easiest!)

**Best For:** Prototypes, hobby projects, learning, quick MVPs

---

### Rank #6: Render.com ⭐⭐⭐

**Best For:** Simple deployments, web services

**What You Get (Free Tier):**
- **Compute:** 512 MB RAM, 0.1 vCPU (limited to 750 hours/month)
- **Database:** PostgreSQL 90 GB (free tier)
- **Deployment:** Git push to deploy
- **Limitations:** Services spin down after 15 min inactivity (cold start ~30 sec)

**Pricing:** $7/month = 512 MB RAM (always on), $25/month = 2 GB RAM

**Pros:**
✅ Free PostgreSQL database (90 GB!)
✅ Simple git push deployment
✅ Good documentation

**Cons:**
❌ Free tier spins down (cold starts)
❌ Only 512 MB RAM
❌ No background workers on free tier
❌ Gets expensive after free tier

**Setup Difficulty:** ⭐ (Very Easy)

**Best For:** Web apps, hobby projects, databases

---

### Rank #7: Fly.io ⭐⭐⭐

**Best For:** Global deployment, edge computing

**What You Get (Free Trial):**
- **Credit:** One-time free credit (varies, often $5-20)
- **Compute:** 256 MB RAM - 2 GB RAM (paid)
- **Pricing:** ~$3-5/month for 512 MB RAM

**Pros:**
✅ Deploy close to users globally
✅ Simple CLI deployment
✅ Good documentation

**Cons:**
❌ Limited free credits (one-time, not recurring)
❌ Gets expensive quickly
❌ Not truly free tier

**Setup Difficulty:** ⭐⭐ (Easy)

**Best For:** Global apps, edge computing

---

## 📊 Comparison Table

| Provider | RAM | CPU | Storage | Bandwidth | Time Limit | Difficulty | Best For |
|----------|-----|-----|---------|-----------|------------|------------|----------|
| **Oracle Cloud** | **24 GB** | 6 OCPU | **400 GB** | **10 TB** | **Forever** | ⭐⭐⭐ | **Production** |
| Google Cloud | 0.6 GB | 0.2 vCPU | 30 GB | 5 GB | 3 mo trial | ⭐ | Learning |
| AWS | 1 GB | 1 vCPU | 30 GB | 100 GB | 12 months | ⭐⭐ | Learning |
| Azure | 1 GB | 1 vCPU | 64 GB | 100 GB | 12 months | ⭐⭐ | Microsoft |
| Railway.app | 512 MB | 0.2 vCPU | 1 GB | 100 GB | Forever | ⭐ | Prototyping |
| Render.com | 512 MB | 0.1 vCPU | - | 100 GB | Forever* | ⭐ | Web apps |

*Render spins down after 15 min inactivity

---

## 🎯 Recommendation for FutureProof

### **Winner: Oracle Cloud Infrastructure (OCI) Always Free** 🏆

**Why OCI is the Best Choice:**

1. **Unbeatable Specs:** 24 GB RAM (Arm-based) vs 1 GB on AWS/GCP
2. **Forever Free:** No time limit, unlike AWS (12 mo) or GCP (3 mo trial)
3. **Massive Bandwidth:** 10 TB/month vs 100 GB on AWS
4. **Plenty Storage:** 400 GB vs 30 GB on others
5. **Production Ready:** Can handle real users
6. **Cost:** $0-5/month (SMS only) vs $20-50/month on Railway/Render

**Perfect for FutureProof because:**
- ✅ PostgreSQL database needs RAM (24 GB is plenty)
- ✅ Redis cache needs RAM
- ✅ Background job processing (Bull) needs CPU
- ✅ Node.js API server needs resources
- ✅ Long-term project (not just a prototype)

---

## 🚀 Oracle Cloud Setup Guide (Step-by-Step)

### Prerequisites

- Credit card (required for verification, but you won't be charged)
- Phone number (for OTP verification)
- 30-60 minutes of time

---

### Step 1: Create Oracle Cloud Account

1. Go to: https://www.oracle.com/cloud/free/
2. Click **"Try Free"** or **"Start for Free"**
3. Fill in:
   - **Email address** (use Gmail/Outlook, not work email)
   - **Full name**
   - **Country/Region** (your actual country)
   - **Phone number** (must be able to receive SMS)
4. Click **"Next"**

---

### Step 2: Verify Email

1. Check your email inbox
2. Look for email from: `no-reply-identity@oracle.com`
3. Click the verification link in the email
4. Your email is now verified

---

### Step 3: Create Account Password

1. Set a strong password (save it in password manager!)
2. Fill in your **Home region** (choose closest to you):
   - **Asia Pacific:** Singapore, Tokyo, Seoul, Sydney, Mumbai, etc.
   - **Europe:** Amsterdam, Frankfurt, London, Milan, Zurich, etc.
   - **Americas:** Sao Paulo, Toronto, Montreal, Phoenix, etc.
   - **Recommended:** Singapore (if you're in SE Asia)
3. Click **"Next"**

---

### Step 4: Add Payment Method (Credit Card)

**Why?** Oracle requires this to prevent abuse. You won't be charged unless you upgrade.

1. Enter **Credit Card details**:
   - Card number
   - Expiry date
   - CVV
   - Billing address
2. Click **"Verify Card"**
3. Oracle will charge a **temporary $1 authorization** ( refunded in 5-7 days)
4. Click **"Continue"**

---

### Step 5: Phone Verification

1. Enter your phone number
2. Click **"Send SMS"**
3. Receive **6-digit OTP** via SMS
4. Enter OTP on the website
5. Click **"Verify"**

---

### Step 6: Wait for Account Provisioning

1. You'll see: **"Your account is being provisioned"**
2. Wait **5-30 minutes** (usually ~10 minutes)
3. You'll receive an email when ready: **"Your Oracle Cloud Free Tier account is ready"**
4. Click **"Sign In"** in the email

**Note:** If you don't receive the email after 1 hour, contact Oracle Support.

---

### Step 7: Sign In to Oracle Cloud Console

1. Go to: https://console.oracle-cloud.com
2. Enter your email and password
3. You may need to verify again via SMS
4. You're now in the **Oracle Cloud Console**!

---

### Step 8: Create SSH Key Pair

**Why?** You'll need SSH keys to securely access your VPS.

**On Windows (PowerShell):**
```powershell
# Check if you have existing SSH key
Test-Path ~/.ssh/id_ed25519

# If not, generate new key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Press Enter to accept default location (~/.ssh/id_ed25519)
# Press Enter for no passphrase (or enter one for extra security)

# Display public key
cat ~/.ssh/id_ed25519.pub
```

**Copy the public key** (starts with `ssh-ed25519 ...`) - you'll need it in next step.

---

### Step 9: Create Compute Instance (VPS)

1. In Oracle Cloud Console, click **hamburger menu** (☰) top-left
2. Navigate to: **Compute** → **Instances**
3. Click **"Create Instance"**
4. Fill in the details:

**Basic Information:**
- **Name:** `futureproof-backend`
- **Compartment:** Leave as default (root compartment)

**Placement:**
- **Availability Domain:** AD 1 (any is fine)
- **Capacity Type:** **Always Free** (IMPORTANT!)

**Shape (VM Configuration):**
- **Shape:** Click **"Change Shape"**
  - Select: **Ampere A1** (ARM-based)
  - Choose: **VM.Standard.A1.Flex** (Always Free eligible)
  - Set: **6 OCPUs** and **24 GB Memory** (max Always Free)
  - Click **"Select Shape"**

**Image (Operating System):**
- **Image:** Click **"Change Image"**
  - Filter by: **Canonical Ubuntu**
  - Select: **Ubuntu 22.04** (or 24.04 if available)
  - Version: **Minimal** (smaller, faster)
  - Click **"Select Image"**

**Networking:**
- **Virtual Cloud Network:** Click **"Create Virtual Cloud Network and Subnet"**
  - **VCN Name:** `futureproof-vcn`
  - **Subnet Name:** `futureproof-subnet`
  - **Subnet Type:** Public Subnet (we want internet access)
  - Click **"Create"**

**SSH Key:**
- **SSH Key Type:** Paste SSH Keys
- **SSH Keys:** Paste your public key from Step 8 (starts with `ssh-ed25519`)

**Boot Volume:**
- **Boot Volume Size:** 50 GB (Always Free allows up to 200 GB)

5. Click **"Create Instance"** button (bottom-right)

---

### Step 10: Wait for Instance to Provision

1. Status will show: **"Provisioning"**
2. Wait **2-5 minutes**
3. Status changes to: **"Running"** ✅

---

### Step 11: Get Public IP Address

1. Click on your instance name: `futureproof-backend`
2. Scroll down to **"Primary VNIC"** section
3. Copy the **Public IP Address** (e.g., `129.213.45.67`)
4. Save it! You'll need it to connect.

---

### Step 12: Connect to Your VPS via SSH

**On Windows (PowerShell):**
```powershell
# Replace with your actual IP address
ssh ubuntu@129.213.45.67

# First time: "The authenticity of host... can't be established."
# Type: yes and press Enter

# You're now connected to your VPS!
# You should see: ubuntu@futureproof-backend:~$
```

**On macOS/Linux:**
```bash
ssh ubuntu@129.213.45.67
```

---

### Step 13: Initial Server Setup

**Run these commands one by one:**

```bash
# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Set timezone (replace Asia/Singapore with your timezone)
sudo timedatectl set-timezone Asia/Singapore

# 3. Create swap file (1 GB - helps with memory)
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 4. Install essential tools
sudo apt install -y curl wget git vim htop net-tools

# 5. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 6. Add your user to docker group (run docker without sudo)
sudo usermod -aG docker ubuntu

# 7. Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 8. Verify Docker installation
docker --version
docker-compose --version

# 9. Enable Docker to start on boot
sudo systemctl enable docker

# 10. Reboot to apply all changes
sudo reboot
```

After reboot, wait 30 seconds and reconnect:
```bash
ssh ubuntu@YOUR_IP_ADDRESS
```

---

### Step 14: Configure Firewall (Security Lists)

**Why?** Only allow necessary traffic (SSH, HTTP, HTTPS).

1. Go back to Oracle Cloud Console
2. Navigate to: **Networking** → **Virtual Cloud Networks**
3. Click on: `futureproof-vcn`
4. Click on: **Security Lists** (left sidebar)
5. Click on: **Default Security List**
6. Click **"Add Ingress Rules"** and add:

**Rule 1: SSH (already exists usually)**
- Source CIDR: `0.0.0.0/0`
- IP Protocol: TCP
- Source Port: All
- Destination Port: **22**
- Description: Allow SSH

**Rule 2: HTTP**
- Source CIDR: `0.0.0.0/0`
- IP Protocol: TCP
- Source Port: All
- Destination Port: **80**
- Description: Allow HTTP

**Rule 3: HTTPS**
- Source CIDR: `0.0.0.0/0`
- IP Protocol: TCP
- Source Port: All
- Destination Port: **443**
- Description: Allow HTTPS

**Rule 4: Custom (for your API, optional)**
- Source CIDR: `0.0.0.0/0`
- IP Protocol: TCP
- Source Port: All
- Destination Port: **3000** (or your API port)
- Description: Allow API access

---

### Step 15: Create Project Directory

```bash
# SSH into your VPS
ssh ubuntu@YOUR_IP_ADDRESS

# Create project directory
mkdir -p ~/futureproof
cd ~/futureproof

# Create directory structure
mkdir -p backend docker postgres-data redis-data logs
```

---

### Step 16: Create Docker Compose File

```bash
# Create docker-compose.yml
vim docker-compose.yml
```

**Paste this content:**
```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: futureproof-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: futureproof
      POSTGRES_PASSWORD: CHANGE_THIS_PASSWORD
      POSTGRES_DB: futureproof
    volumes:
      - ./postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - futureproof-network

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: futureproof-redis
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - ./redis-data:/data
    ports:
      - "6379:6379"
    networks:
      - futureproof-network

  # Node.js Backend API (you'll create this later)
  api:
    build: ./backend
    container_name: futureproof-api
    restart: unless-stopped
    environment:
      NODE_ENV: production
      PORT: 3000
      DATABASE_URL: postgresql://futureproof:CHANGE_THIS_PASSWORD@postgres:5432/futureproof
      REDIS_URL: redis://redis:6379
      JWT_SECRET: CHANGE_THIS_SECRET
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
    networks:
      - futureproof-network

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: futureproof-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - api
    networks:
      - futureproof-network

networks:
  futureproof-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
```

**Save and exit:** Press `Esc`, type `:wq`, press `Enter`

---

### Step 17: Start Docker Containers

```bash
# Start all services
docker-compose up -d

# Check if containers are running
docker ps

# Check logs
docker-compose logs -f

# View specific container logs
docker logs futureproof-db
docker logs futureproof-redis
```

---

### Step 18: Install Nginx Configuration

```bash
# Create nginx directory
mkdir -p ~/futureproof/nginx/ssl
cd ~/futureproof/nginx

# Create nginx.conf
vim nginx.conf
```

**Paste this content:**
```nginx
events {
    worker_connections 1024;
}

http {
    upstream api {
        server api:3000;
    }

    server {
        listen 80;
        server_name _;

        # Redirect HTTP to HTTPS (once SSL is set up)
        # return 301 https://$server_name$request_uri;

        location / {
            proxy_pass http://api;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
    }

    # HTTPS server (configure after obtaining SSL certificate)
    # server {
    #     listen 443 ssl http2;
    #     server_name your-domain.com;
    #
    #     ssl_certificate /etc/nginx/ssl/fullchain.pem;
    #     ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    #
    #     location / {
    #         proxy_pass http://api;
    #         proxy_http_version 1.1;
    #         proxy_set_header Upgrade $http_upgrade;
    #         proxy_set_header Connection 'upgrade';
    #         proxy_set_header Host $host;
    #         proxy_cache_bypass $http_upgrade;
    #     }
    # }
}
```

**Save and exit:** Press `Esc`, type `:wq`, press `Enter`

```bash
# Restart nginx
docker-compose restart nginx

# Test if nginx is working
curl http://localhost
```

---

### Step 19: Install SSL Certificate (Let's Encrypt)

**Option 1: With Domain Name (Recommended)**

```bash
# Install Certbot
sudo apt install -y certbot

# Obtain certificate (replace with your actual domain)
sudo certbot certonly --standalone -d your-domain.com

# Certificates will be saved to:
# /etc/letsencrypt/live/your-domain.com/fullchain.pem
# /etc/letsencrypt/live/your-domain.com/privkey.pem

# Copy certificates to nginx directory
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ~/futureproof/nginx/ssl/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ~/futureproof/nginx/ssl/

# Set permissions
sudo chown ubuntu:ubuntu ~/futureproof/nginx/ssl/*.pem
```

**Option 2: Without Domain (Self-Signed Certificate)**

```bash
# Generate self-signed certificate
cd ~/futureproof/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout privkey.pem \
  -out fullchain.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

---

### Step 20: Test Your Setup

```bash
# Check if all containers are running
docker ps

# Test PostgreSQL connection
docker exec -it futureproof-db psql -U futureproof -d futureproof -c "SELECT version();"

# Test Redis connection
docker exec -it futureproof-redis redis-cli ping
# Should return: PONG

# Test API (once you build the backend)
curl http://YOUR_IP_ADDRESS:3000/health

# Test Nginx
curl http://YOUR_IP_ADDRESS
```

---

## 🎉 Congratulations!

You now have a **free VPS** with:
- ✅ Ubuntu 22.04 (ARM64)
- ✅ Docker & Docker Compose
- ✅ PostgreSQL Database
- ✅ Redis Cache
- ✅ Nginx Reverse Proxy
- ✅ SSL/TLS (optional)
- ✅ 24 GB RAM
- ✅ 6 OCPUs
- ✅ 200 GB Storage
- ✅ 10 TB/month bandwidth

**Cost:** $0/month (forever!)

---

## 📝 Next Steps

1. **Build your Node.js backend API** (refer to REDESIGN_PLAN.md)
2. **Deploy backend to Docker container**
3. **Configure domain name** (optional, but recommended)
4. **Set up CI/CD pipeline** (GitHub Actions)
5. **Configure monitoring** (Oracle Cloud Monitoring)
6. **Implement authentication** (JWT, OAuth)
7. **Build sync endpoints** (push/pull)
8. **Update Flutter app** to connect to new backend

---

## 🔧 Useful Commands

```bash
# SSH into VPS
ssh ubuntu@YOUR_IP_ADDRESS

# Check Docker containers
docker ps -a

# View container logs
docker logs -f futureproof-api

# Restart containers
docker-compose restart

# Stop all containers
docker-compose stop

# Start all containers
docker-compose start

# Update Docker images
docker-compose pull
docker-compose up -d --build

# Check system resources
htop

# Check disk space
df -h

# Check memory
free -h

# Reboot VPS
sudo reboot
```

---

## 🔐 Security Checklist

- [ ] SSH key-only authentication (no password login)
- [ ] Firewall configured (only allow necessary ports)
- [ ] Strong PostgreSQL password (change in docker-compose.yml)
- [ ] Strong JWT secret (change in docker-compose.yml)
- [ ] SSL/TLS certificate installed
- [ ] Regular security updates: `sudo apt update && sudo apt upgrade -y`
- [ ] Fail2ban installed (to block brute-force attacks)
- [ ] Automated backups configured (Oracle Cloud Object Storage)

---

## 🆘 Troubleshooting

**Can't connect via SSH:**
- Check if VPS is running in Oracle Cloud Console
- Check firewall rules (Security Lists)
- Check your SSH key: `ssh-keygen -l -f ~/.ssh/id_ed25519.pub`

**Container won't start:**
- Check logs: `docker logs <container-name>`
- Check if port is already in use: `sudo netstat -tulpn`
- Check Docker disk space: `docker system df`

**Out of memory:**
- Check swap is enabled: `free -h`
- Add more swap: `sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile`

**PostgreSQL connection refused:**
- Check if container is running: `docker ps | grep postgres`
- Check logs: `docker logs futureproof-db`
- Wait 30 seconds after container start for PostgreSQL to initialize

---

## 📚 Resources

- **Oracle Cloud Documentation:** https://docs.oracle.com/en-us/iaas/
- **Ubuntu 22.04 Documentation:** https://ubuntu.com/server/docs
- **Docker Documentation:** https://docs.docker.com/
- **PostgreSQL Documentation:** https://www.postgresql.org/docs/
- **Nginx Documentation:** https://nginx.org/en/docs/

---

**Generated by:** Claude Code
**Date:** 2026-01-16
**Status:** Ready for implementation
