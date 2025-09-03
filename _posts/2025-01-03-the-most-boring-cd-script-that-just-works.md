---
title: "The Most Boring CD Script That Just Works"
date: 2025-09-03 12:00:00 +0000
categories: [DevOps, Deployment]
tags: [bash, continuous-deployment, simplicity, nginx, gcp]
---

Here's my entire continuous deployment pipeline for the blog that you are reading:

```bash
#!/bin/bash

while true
do
  git pull
  jekyll build
  sudo rsync -r _site/* /var/www/html
  echo sleeping...
  sleep 300
done
```

That's it. Ten lines.

## The Setup

- GCP VM with nginx
- [Git repo](https://github.com/sapienfrom2000s/portfolio) cloned on server
- `nohup ./auto_deployer.sh &`

Every 5 minutes: pull changes, build site, copy to `/var/www/html`.

## Why This Beats Jenkins/GitHub Actions

No build queues. No service outages. No YAML. No secrets management. No monthly bills.

Want to change deployment? Edit the script. Done.

## When to Use This

Perfect for personal sites, blogs, documentation. Don't use for production apps with teams.

## The Experiment

I just started running this script. Instead of jumping straight to Jenkins or GitHub Actions like everyone else, I'm curious to see how this simple approach pans out.

The beauty is that if something breaks, I'll know exactly what went wrong and where. No digging through CI/CD logs or debugging YAML syntax errors.

Sometimes the most boring solution is the best solution.
