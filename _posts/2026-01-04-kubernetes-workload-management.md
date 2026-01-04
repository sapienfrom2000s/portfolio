---
title: "Kubernetes - Workload Management"
date: 2026-01-09 12:45:00 +0530
categories: [K8s]
tags: [kubernetes, deployments, replicasets, statefulsets, daemonsets, jobs, cronjobs]
---

# Overview

Workload is an application running on k8s. Application is spinned on pod. K8s offers various kind of 
resource for managing various type of workloads. Resources that we will be talking below are:
1. Deployment
2. ReplicaSet
3. StatefulSet
4. DaemonSet
5. Job
6. CronJob

## Deployments

Deployment is a k8s resource/object which is responsible for spawning deployment controller. The
controller is responsible for rolling out/back of releases and maintaining replicasets. Replicaset
in turn is responsible for maintaining pods. Deployment object looks like this:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-container
        image: my-image:latest
```

Anything updated inside `.spec.template` leads to creation of new deployment by creating a new
replicaset. Updating `.spec.replicas` leads to just updating the replicaset object.

### What happens when half deployment has rolled out and user pauses it?
Both old and new Pods continue receiving traffic. Rollout immediately stops.

### Understanding maxSurge and maxUnavailable

**maxSurge**: The maximum number of extra pods that can be created above the desired replica count 
during the update. During a rolling update, Kubernetes will terminate old pods. maxUnavailable sets a 
limit on how many pods can be down at once, ensuring you maintain a minimum number of running pods.

**maxUnavailable**: The maximum number of pods that can be unavailable during the update process.
During a rolling update, Kubernetes creates new pods before terminating old ones. maxSurge sets a limit 
on how many extra pods can exist temporarily.

**maxSurge: 2, maxUnavailable: 1**

Start: [10 + 0 = 10] Available: 10
Step 1: Create 2 new → [10 + 2 = 12] Available: 10 → wait for ready → Available: 12
Step 2: Terminate 3 old (can drop to 9 available) → [7 + 2 = 9] Available: 9
Step 3: Create 2 new → [7 + 4 = 11] Available: 9 → ready → Available: 11 → Terminate 3 old → Repeat 
until done

Min number of pods: 9

**maxSurge: 2, maxUnavailable: 0**
Start: [10 + 0 = 10] Available: 10
Step 1: Create 2 new → [10 + 2 = 12] Available: 10 → wait for ready → Available: 12
Step 2: Terminate 2 old (must keep 10 available) → [8 + 2 = 10] Available: 10
Step 3: Create 2 new → [8 + 4 = 12] Available: 10 → ready → Available: 12 → Terminate 2 old → Repeat 
until done

Min number of pods: 10

**maxSurge: 0, maxUnavailable: 2**
Start: [10 + 0 = 10] Available: 10
Step 1: Terminate 2 old (can drop to 8 available) → [8 + 0 = 8] Available: 8
Step 2: Create 2 new → [8 + 2 = 10] Available: 8 → wait for ready → Available: 10
Step 3: Terminate 2 old → [6 + 2 = 8] Available: 8 → Create 2 new → [6 + 4 = 10] Available: 8 → Repeat 
until done

Min number of pods: 8

*The second configuration gives zero downtime(always at max capacity). maxSurge > 0 and maxUnavailable 
= 0*

## What happens when a deployment is created?

1. User sends the Deployment request to the API server. Then it saves the Deployment information in 
etcd, which is the database.
2. The Deployment Controller notices the new Deployment. It creates a ReplicaSet based on user's 
specifications. The ReplicaSet knows how many Pods you want.
3. The ReplicaSet Controller sees it needs to create Pods. It creates the exact number of Pod objects 
user requested.
4. The Scheduler finds Pods that don't have a node assigned.
5. Kubelet Starts Containers
6. The controllers keep watching everything. If a Pod dies, they create a replacement. If user update 
the Deployment, they roll out changes gradually. The system maintains your desired state automatically.
