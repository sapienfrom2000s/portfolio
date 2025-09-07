---
title: "Building My Portfolio: From Zero to Deployed"
date: 2025-09-06 12:00:00 +0000
categories: [DevOps, Web Development]
tags: [terraform, gcp, jekyll, nginx, infrastructure, portfolio]
---

I built and deployed my portfolio site after reading [Logan Marchione's post](https://loganmarchione.com/2022/10/the-best-devops-project-for-a-beginner/) about DevOps projects for beginners.

The project covers infrastructure provisioning, server configuration, web server setup, DNS management, and deployment.

## The Starting Point

I had a [Jekyll app](https://github.com/sapienfrom2000s/portfolio) in a repository that needed to be deployed.

## Infrastructure as Code

First step: [Terraform script](https://github.com/sapienfrom2000s/thirtyone-terraform) to provision infrastructure on Google Cloud Platform.

```hcl
# The usual suspects - VPC, firewall rules, compute instance
resource "google_compute_instance" "portfolio_vm" {
  name         = "portfolio-server"
  machine_type = "e2-micro"  # Free tier FTW
  zone         = "us-central1-a"
  
  # ... networking, disks, etc
}
```

Configuration:
- **Ingress and Egress rules**: Opened HTTP (80) and HTTPS (443) ports
- **SSH access**: Port 22 for remote management
- **Instance type**: e2-micro (free tier)

## Server Setup

Server setup steps:

```bash
# Always start here
sudo apt update && sudo apt upgrade -y

# Essential tools
sudo apt install -y git nginx certbot python3-certbot-nginx

# Ruby environment for Jekyll
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
rbenv install 3.1.0
rbenv global 3.1.0
```

## The Build Process

Cloned the Jekyll repo, installed dependencies, and built the site:

```bash
git clone https://github.com/username/portfolio.git
cd portfolio
bundle install
jekyll build
```

Configured nginx to serve the `_site` directory:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/portfolio/_site;
    index index.html;
}
```

## Domain Setup

Purchased a domain at Namecheap for ₹300 and configured DNS with an A record pointing to the GCP VM's external IP.

```
Type: A
Host: @
Value: 34.123.456.789  # Your VM's IP
TTL: Automatic
```

## The Moment of Truth

Typed the domain into my browser. It worked. Yayy!

## SSL Certificate

With certbot installed, getting an SSL certificate was straightforward:

```bash
sudo certbot --nginx -d your-domain.com
```

Certbot automatically updated the nginx configuration and set up auto-renewal. HTTPS enabled ✅

## Next Steps

Now I have a foundation to build on:
- ~~Automated deployments~~ ✅ [Done](/2025/01/03/the-most-boring-cd-script-that-just-works.html)
- **Ansible playbooks** for server configuration management
- Monitoring and logging
- Maybe a CDN if I'm feeling fancy

## Summary

This project covers the full deployment stack:
- Infrastructure provisioning with Terraform
- Server administration and configuration
- Web server setup with nginx
- SSL certificate management
- DNS configuration
- Application deployment