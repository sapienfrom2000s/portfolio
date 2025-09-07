---
title: "Building My Portfolio: From Zero to Deployed"
date: 2025-09-06 12:00:00 +0000
categories: [DevOps, Web Development]
tags: [terraform, gcp, jekyll, nginx, infrastructure, portfolio]
---

I finally did it. After years of saying "I should build a proper portfolio site," I actually built one. The trigger? Reading [Logan Marchione's excellent post](https://loganmarchione.com/2022/10/the-best-devops-project-for-a-beginner/) about the best DevOps project for beginners.

He was right. Building and deploying your own site teaches you everything: infrastructure, networking, web servers, DNS, and deployment. Plus, you get something useful at the end.

## The Starting Point

I already had a [Jekyll app](https://github.com/sapienfrom2000s/portfolio) sitting in a repo, gathering digital dust. Classic developer move - build the thing, never deploy it. Time to fix that.

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

Key decisions:
- **Ingress and Egress rules**: Opened HTTP (80) and HTTPS (443) ports
- **SSH access**: Port 22 for remote management
- **Minimal specs**: e2-micro instance because this isn't Netflix

## Server Setup

Once the VM was running, the usual server prep:

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

Then pointed nginx at the `_site` directory. Simple nginx config:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/portfolio/_site;
    index index.html;
}
```

## Making It Real

The final piece: making it accessible to the world.

Bought a domain at Namecheap for around ₹300, then added an A record pointing to my GCP VM's external IP.

```
Type: A
Host: @
Value: 34.123.456.789  # Your VM's IP
TTL: Automatic
```

## The Moment of Truth

Typed the domain into my browser. It worked.

That feeling when you see your own site, running on your own infrastructure, accessible from anywhere in the world? Pure magic.

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

## Why You Should Do This Too

Logan was right - this is the perfect beginner DevOps project. You touch every part of the stack:
- Infrastructure provisioning
- Server administration  
- Web server configuration
- DNS management
- Application deployment

And at the end, you have something real. Something that's yours.