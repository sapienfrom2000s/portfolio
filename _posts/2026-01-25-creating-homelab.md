---
title: "Creating a Homelab"
date: 2026-01-25 10:00:00 +0530
categories: [homelab]
tags: [selfhost, homelab, k8s-cluster]
---

# Motivation

These days I spend my time on learning and exploring tools around k8s. I have access to
company's k8s cluster but I can't break the cluster while experimenting. I have some free
credits lying around in google cloud, but I think that will consume the credits very fast plus
managed clusters hide a lot of abstractions from user. I had a old laptop lying around, so I
thought of host my own k8s cluster on top of it.

# Tools & Hardware

Tools:
  - kubeadm - to initialize the cluster
  - calico - CNI plugin
  - docker - container runtime
  - cri - cri-dockerd

Hardware:
  - Device - HP Elite Book 745 G2
  - OS - Lubuntu 22.04.3 LTS x86_64
  - Kernel - 6.2.0-26-generic
  - RAM - 16GB RAM
  - CPU - AMD A10 PRO-7350B R6 4C+6G (4) @ 2.100GHz
  - GPU - AMD ATI Radeon R6/R7 Graphics

Will be running a single node cluster.

# Setup

## Step 1 - Connecting to Elitebook

There are 3 devices behind the router - Mac, Elite Book and My Phone. Since, all of them are
often connected to the same network, the router remembers and assigns them a definite and predictable
IP each time.

Router - 192.168.1.1
Elite Book - 192.168.1.2
Mac - 192.168.1.3
My Phone - 192.168.1.4

I installed openssh-server on my old laptop so that I can ssh from my macbook easily. I was able to ssh
into my old laptop from the internal network using password. But I wanted to bypass this step. So, I added
my public key to the authorized_keys file on my old laptop.

## Step 2 - Setting up the cluster with kubeadm

--To be continued--
