---
title: "Kubernetes - Workload Management"
date: 2026-01-04 12:45:00 +0530
categories: [K8s]
tags: [kubernetes, deployments, replicasets, statefulsets, daemonsets, jobs, cronjobs]
---

# Overview

A workload is an application running on Kubernetes. Applications ultimately run inside Pods, and Kubernetes provides several higher‑level resources to
manage Pods depending on workload characteristics such as stateless vs stateful, long‑running vs batch, or node‑level concerns.

In this article, we cover the following workload resources:

1. Deployment
2. ReplicaSet
3. StatefulSet
4. DaemonSet
5. Job
6. CronJob

---

## Deployments

A Deployment is a Kubernetes resource that manages the lifecycle of stateless applications. It creates and manages **ReplicaSets**, which in turn create and maintain **Pods**.

The Deployment controller is responsible for:
- Rolling updates and rollbacks
- Scaling replicas

### Important behavior

- Any change inside `.spec.template` (image, env vars, labels, etc.) creates a **new ReplicaSet**.
- Updating `.spec.replicas` only changes the replica count of the **existing ReplicaSet**.

---

### What happens when a rollout is paused mid‑way?

If a rollout is paused:
- Already created new Pods continue running
- Remaining old Pods are not terminated
- Both old and new Pods continue receiving traffic
- No further rollout progress happens until resumed

---

### Understanding `maxSurge` and `maxUnavailable`

These fields control how Pods are replaced during a rolling update.

- **maxSurge**: Maximum number of Pods that can be created *above* the desired replica count.
- **maxUnavailable**: Maximum number of Pods that can be unavailable during the update.

> Kubernetes always tries to respect **both** constraints simultaneously.

---

#### Example: `replicas=10`, `maxSurge=2`, `maxUnavailable=1`

1. Start with 10 available Pods
2. Up to 2 extra Pods can be created → total Pods = 12
3. After new Pods become Ready, availability = 12
4. Old Pods can now be deleted, but availability can drop only by 1
5. Kubernetes deletes 3 old Pods → availability drops to 9
6. The cycle repeats

**Minimum available Pods at any point: 9**

---

#### `maxSurge=2`, `maxUnavailable=0`

- Kubernetes creates new Pods before deleting any old ones
- Guarantees zero downtime (assuming readiness probes are correct)

**Minimum available Pods at any point: 10**

---

#### `maxSurge=0`, `maxUnavailable=2`

1. Kubernetes must delete old Pods first
2. Availability drops from 10 → 8
3. New Pods are created to restore replica count
4. Availability remains 8 until Pods become Ready

**Minimum available Pods at any point: 8**

---

## What happens when a Deployment is created?

1. User sends the Deployment manifest to the **API Server**
2. API Server validates and stores it in **etcd**
3. **Deployment Controller** creates a ReplicaSet
4. **ReplicaSet Controller** creates the desired number of Pods
5. **Scheduler** assigns Pods to Nodes
6. **Kubelet** on each Node pulls images and starts containers
7. Controllers continuously reconcile desired vs actual state

---

## ReplicaSet

A **ReplicaSet** ensures that a specified number of identical Pods are running at any time.

> In practice, users rarely create ReplicaSets directly. Deployments manage them automatically.

---

## StatefulSet

**StatefulSets** are used for stateful applications such as databases and distributed systems.

They provide:
- Stable Pod identities
- Stable network identities
- Stable storage using PersistentVolumeClaims
- Ordered creation and deletion

### Example: MySQL (1 master, 3 replicas)

#### 1. How does each Pod get a separate PVC?

StatefulSets use `volumeClaimTemplates`. Kubernetes creates one PVC per Pod automatically.

#### 2. How do you ensure only the master accepts writes?

This is handled **at the application level**, not by Kubernetes:
- Use MySQL replication configuration (read‑only replicas)
- Expose master and replicas via **different Services**

#### 3. How does a Pod reattach to the same PVC after restart?

Each Pod has a **stable identity**:

- Pod name: `mysql-0`, `mysql-1`, `mysql-2`
- PVC name: `data-mysql-0`, `data-mysql-1`, `data-mysql-2`

When a Pod is recreated, Kubernetes uses the same name, so it automatically rebinds to the same PVC.

---

### What happens during StatefulSet updates?

- Pods are updated **one at a time** (by default)
- Higher ordinal Pods are updated first
- Lower ordinal Pods wait until higher ones become Ready
- Storage remains intact due to stable PVC binding

---

### Headless Service

A **Headless Service** is a Service with `clusterIP: None`.

- No load‑balancing IP is created
- DNS returns individual Pod IPs
- Used heavily with StatefulSets

Example use cases:
- Talking directly to `mysql-0` (master)
- Replicas discovering each other for replication

---

### Why not use StatefulSet everywhere?

StatefulSets introduce:
- Slower rollouts
- Strict ordering constraints
- Higher operational complexity

For stateless workloads, Deployments are simpler, faster, and more flexible.

---

## DaemonSet

A **DaemonSet** ensures that a Pod runs on **every Node** (or a selected set of Nodes).

Typical use cases:
- Log collectors (Fluent Bit)
- Monitoring agents (Node Exporter)
- Network plugins (CNI)

---

## Job

A **Job** runs a task to completion.

- Ensures the Pod runs successfully
- Retries on failure
- Suitable for batch and one‑time workloads

Examples:
- Database migrations
- Backup jobs
- Data processing tasks

---

## CronJob

A **CronJob** schedules Jobs to run periodically using cron syntax.

Common use cases:
- Periodic backups
- Cleanup tasks
- Scheduled reports

---

## Final Thoughts

Kubernetes workload primitives are designed with clear separation of concerns. Choosing the right workload type simplifies operations, improves reliability, and avoids unnecessary complexity. Use:

- **Deployment** for stateless services
- **StatefulSet** for stateful systems
- **DaemonSet** for node‑level agents
- **Job / CronJob** for batch and scheduled tasks
