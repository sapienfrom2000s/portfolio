---
title: "Why K8s"
date: 2025-11-02 12:00:00 +0000
categories: [K8s]
tags: [kubernetes]
---

Docker was released in 2013. It became a hit instantly as it made the applications more portable and easy to replicate in different environments. Companies were already providing VM services at this time. It became easy to tear up and tear down servers with a simple API call. So if you wanted to host something, you would create a VM and run a container on top of it. But what if you had a bigger scale that can't be satisfied by a single node/VM. Sure, I can place a load balancer in front and host the server in two different machines. What if a container dies in the middle of something for some reason. Sure, you can put `restart: always` which will restart the container if it goes down. What if your app becomes a massive hit and the scale increases. Obviously, you can put new machines behind the load balancer. What if I had a microservice in machine A that needs to talk to machine B. We can whitelist an IP in the firewall and make them both talk to each other via some protocol. How do you update your applications making sure that you don't get downtimes?

K8s is a **container orchestration** tool that allows to manage cluster of nodes at the same time. It allows users to host their application across multiple nodes. Configuration can be written in yaml files and can be applied by a single command. Need to increase servers, just increase the replica count and apply the configuration. Need microservices to talk to each other, use svc. Don't know how many replicas is needed, use autoscaler groups. It also provides bunch of release strategies which can be chosen as per user needs to make sure that the deployment happens without any downtime.

Alternatives: Docker Swarm, Nomad
