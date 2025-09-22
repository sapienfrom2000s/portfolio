---
title: "Monitoring Kubernetes with Prometheus and Grafana: A Quick Overview"
date: 2025-09-12 12:00:00 +0000
categories: [DevOps, Web Development]
tags: [prometheus, grafana, devops, monitoring]
---

<img src="{{site.baseurl}}/assets/img/prometheus-infra.png">

Prometheus is a opensource tool that exports and serves metrics. Metrics
can be of server, application or anything that a user wants to track. I wanted
to track resources of k8s cluster. For POC, I installed it in my cluster via helm.
Exposed endpoint in server for scraper to scrape it and push it to prometheus server.
The server then serves the metrics for anyone who is interested in consuming the info
(Prometheus UI, Grafana).
