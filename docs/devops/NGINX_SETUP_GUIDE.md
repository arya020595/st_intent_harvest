# Nginx Setup Guide

## Overview

Configure Nginx as reverse proxy for two Rails apps + static site:

- `intentharvest.com` → static HTML site
- `intent.intentharvest.com` → st_intent_harvest (port 3005)
- `accorn.intentharvest.com` → st_accorn (port 3006)

---

## Quick Setup

### 1. Install Nginx

```bash
sudo apt update && sudo apt install nginx -y
sudo systemctl enable nginx

# Allow firewall access
sudo ufw allow 22/tcp    # SSH - keep your remote access
sudo ufw allow 80/tcp    # HTTP - for web traffic and SSL verification
sudo ufw allow 443/tcp   # HTTPS - for secure web traffic
sudo ufw enable
```

**Why allow these ports:**

- **Port 22 (SSH)**: Required to keep remote terminal access to your server
- **Port 80 (HTTP)**: Required for:
  - Initial website access before SSL setup
  - Let's Encrypt SSL certificate verification
  - Auto-redirect from HTTP to HTTPS (after SSL)
- **Port 443 (HTTPS)**: Required for secure encrypted web traffic after SSL setup

### 2. Setup Static Site (intentharvest.com)

```bash
# Create directory for static site
sudo mkdir -p /var/www/intentharvest.com

# Copy your static files to the directory
sudo cp /home/stadmin/st_intent/*.html /var/www/intentharvest.com/
sudo cp /home/stadmin/st_intent/*.css /var/www/intentharvest.com/
sudo cp /home/stadmin/st_intent/*.png /var/www/intentharvest.com/
sudo cp /home/stadmin/st_intent/*.webp /var/www/intentharvest.com/

# Set proper permissions
sudo chown -R www-data:www-data /var/www/intentharvest.com
sudo chmod -R 755 /var/www/intentharvest.com
```

### 3. Create Nginx Config for Static Site

```bash
sudo nano /etc/nginx/sites-available/intentharvest.com
```

Paste this:

```
server {
  listen 80;
  listen [::]:80;
  server_name intentharvest.com www.intentharvest.com;

  root /var/www/intentharvest.com;
  index index.html;

  access_log /var/log/nginx/intentharvest.com_access.log;
  error_log /var/log/nginx/intentharvest.com_error.log;

  location / {
    try_files $uri $uri/ =404;
  }

  # Cache static assets
  location ~* \.(jpg|jpeg|png|gif|ico|css|js|webp)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
  }
}
```

### 4. Create Nginx Config for Intent Harvest

```bash
sudo nano /etc/nginx/sites-available/intent.intentharvest.com
```

Paste this (DON'T include the word "nginx" at top):

```
upstream intent_harvest {
  server 127.0.0.1:3005 fail_timeout=0;
}

server {
  listen 80;
  listen [::]:80;
  server_name intent.intentharvest.com;

  access_log /var/log/nginx/intent.intentharvest.com_access.log;
  error_log /var/log/nginx/intent.intentharvest.com_error.log;

  client_max_body_size 100M;

  location / {
    proxy_pass http://intent_harvest;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_redirect off;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
  }
}
```

### 5. Create Nginx Config for Accorn

```bash
sudo nano /etc/nginx/sites-available/accorn.intentharvest.com
```

Paste this:

```
upstream accorn {
  server 127.0.0.1:3006 fail_timeout=0;
}

server {
  listen 80;
  listen [::]:80;
  server_name accorn.intentharvest.com;

  access_log /var/log/nginx/accorn.intentharvest.com_access.log;
  error_log /var/log/nginx/accorn.intentharvest.com_error.log;

  client_max_body_size 100M;

  location / {
    proxy_pass http://accorn;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_redirect off;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
  }
}
```

### 6. Enable All Sites

```bash
sudo ln -s /etc/nginx/sites-available/intentharvest.com /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/intent.intentharvest.com /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/accorn.intentharvest.com /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
```

### 7. Test and Reload

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 8. Configure Docker Ports

Ensure your `docker-compose.yml` has correct port mappings:

**st_intent_harvest:**

```yaml
ports:
  - "3005:3000"
```

**st_accorn:**

```yaml
ports:
  - "3006:3000"
```

### 7. Start Docker Containers

```bash
cd /home/arya020595/Documents/work/st_intent_harvest
docker-compose up -d

cd /home/arya020595/Documents/work/st_accorn
docker-compose up -d
```

### 10. Setup SSL for All Domains

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate for static site (intentharvest.com only, not www)
sudo certbot --nginx -d intentharvest.com

# Get SSL certificates for Rails apps
sudo certbot --nginx -d intent.intentharvest.com
sudo certbot --nginx -d accorn.intentharvest.com
```

**Note:** If using Cloudflare, get certificate for `intentharvest.com` only (without www). Cloudflare will handle SSL for www subdomain.

When prompted:

1. Enter your email
2. Agree to terms (Y)
3. Choose option 2 (redirect HTTP to HTTPS)

**Verify SSL setup:**

```bash
# Check certificates
sudo certbot certificates

# Test HTTPS access
curl -I https://intentharvest.com
curl -I https://intent.intentharvest.com
curl -I https://accorn.intentharvest.com
```

---

## Useful Commands

```bash
# Check status
docker ps
sudo systemctl status nginx
sudo certbot certificates

# View logs
docker-compose logs -f
sudo tail -f /var/log/nginx/intent.intentharvest.com_error.log

# Restart services
docker-compose restart
sudo systemctl reload nginx

# Update application
docker-compose pull && docker-compose up -d
```

## Troubleshooting

**502 Bad Gateway**

```bash
docker ps  # Check if container is running
docker-compose restart
```

**Blocked host error**

Add to `.env` file:

```env
RAILS_ALLOWED_HOSTS=intent.intentharvest.com,accorn.intentharvest.com,localhost
```

Then restart containers.

**Nginx syntax error**

Don't copy markdown code fences (```nginx) into the actual config file.

**Static site showing Rails app instead**

This happens when:

1. Default site is still enabled - remove it: `sudo rm /etc/nginx/sites-enabled/default`
2. Certbot added wrong config to HTTPS section - check that port 443 block has `root /var/www/intentharvest.com;` not `proxy_pass`
3. Browser cache - test in incognito mode or use `curl`

**SSL certificate error for www subdomain**

If using Cloudflare:

- Get certificate for apex domain only: `sudo certbot --nginx -d intentharvest.com`
- Cloudflare will handle SSL for www subdomain automatically
- Keep `server_name` with both domains: `intentharvest.com www.intentharvest.com`

---

## Final Result

✅ https://intentharvest.com (static site)
✅ https://intent.intentharvest.com (Rails app)
✅ https://accorn.intentharvest.com (Rails app)
✅ Auto SSL renewal
✅ HTTP redirects to HTTPS
