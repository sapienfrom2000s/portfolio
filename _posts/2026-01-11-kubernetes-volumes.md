---
title: "Kubernetes - Volumes"
date: 2026-01-11 04:40:00 +0530
categories: [K8s]
tags: [kubernetes, volumes]
---

## 1. Why Storage Is Hard in Kubernetes

Containers are **ephemeral by design**:
- Containers restart
- Pods get rescheduled
- Nodes fail

By default, **container filesystems do not persist**.

Kubernetes solves this problem using **Volumes**, which decouple **data** from **containers**.

---

## 2. Kubernetes Volumes: The Foundation

A **Volume** is a directory mounted into a container, backed by some storage.

### Key Properties
- Defined at the **Pod level**
- Data survives **container restarts**
- Shared between containers in the same Pod
- Exists as long as the **Pod exists**

Volumes are the base abstraction for all Kubernetes storage.

---

## 3. Ephemeral Volumes: Pod-Scoped Temporary Storage

**Ephemeral volumes** exist only for the **lifetime of a Pod**.

### Common Types
- `emptyDir` – scratch space, caching, shared workspace
- `configMap` – configuration files
- `secret` – credentials
- `downwardAPI` – Pod metadata

### When to Use
1. Caches  
2. Temporary files  
3. Shared workspace  
4. Config and secret injection  

---

## 4. The Real Problem: Data That Must Survive Pods

Stateful workloads (databases, queues, file systems) must survive:
- Pod restarts
- Rescheduling
- Node failures

This requires **Persistent Storage**.

---

## 5. PersistentVolume (PV): The Actual Storage

A **PersistentVolume (PV)** is a **cluster-level storage resource**.

### Characteristics
- Independent of Pods
- Represents real storage
- Created manually or dynamically
- Has capacity, access modes(R, RW), reclaim policy

**PV is infrastructure-oriented** ie- it represents actual physical or cloud storage.

---

## 6. PersistentVolumeClaim (PVC): Storage Request

A **PVC** is a **request for storage** by an application.

### PVC Specifies
- Storage size
- Access mode

Kubernetes binds the PVC to a matching PV.

**PVC is application-oriented.**

---

### 7. PV vs PVC; tldr

> PV is supply, PVC is demand — Kubernetes does the matching.

---

## 8. StorageClass: Blueprint for Storage

A **StorageClass** defines **how storage is provisioned**.

### What It Controls
- Storage backend (CSI driver)
- Performance tier
- Reclaim policy
- Volume expansion
- Binding behavior

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```
provisioner – Specifies which CSI driver will create the storage volume (here, AWS EBS CSI).
parameters – Defines storage-specific settings such as disk type, performance, or filesystem.
reclaimPolicy – Determines what happens to the underlying storage when the PVC is deleted (Retain or Delete).
allowVolumeExpansion – Allows the volume size to be increased after it has been created.
volumeBindingMode – Controls when the volume is provisioned; WaitForFirstConsumer waits until a Pod is scheduled to avoid zone mismatch issues.

Enables **dynamic provisioning** — no manual PV creation.

---

## 9. CSI Drivers: How Kubernetes Talks to Storage

**CSI (Container Storage Interface)** is the standard interface for storage plugins.

### Why CSI Exists
Before CSI:
- Storage code lived inside Kubernetes core
- Hard to maintain and extend

With CSI:
- Storage plugins are external
- Vendors ship and maintain drivers
- Kubernetes core remains stable

### CSI Responsibilities
- Create/delete volumes
- Attach/detach volumes
- Mount/unmount volumes
- Resize volumes
- Create snapshots

---

## 10. Projected Volumes: Clean Config & Secret Injection

A **Projected Volume** combines multiple volume sources into **one directory**.

### Supported Sources
- Secret
- ConfigMap

### Why It’s Useful
- Single mount point
- Cleaner Pod specs
- Easier application logic

Commonly used for **config + credentials + metadata**.

---

## Final TL;DR

- Volumes solve container filesystem ephemerality
- Ephemeral volumes are Pod-lifetime only
- PV/PVC decouple storage from compute
- StorageClasses enable dynamic provisioning
- CSI drivers are the modern storage standard
- Projected volumes simplify config & secret management
