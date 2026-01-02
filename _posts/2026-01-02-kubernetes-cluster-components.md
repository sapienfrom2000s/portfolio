---
title: "Kubernetes - Cluster Components"
date: 2026-01-01 12:45:00 +0530
categories: [K8s]
tags: [kubernetes, control-plane, worker-nodes]
---

A k8s cluster generally has two types of machines:
1. Control Plane
2. Worker Nodes(called minions sometimes)

## Control Plane

The control plane is the heart of the Kubernetes cluster. It is responsible for managing the cluster
and ensuring that the desired state of the cluster is achieved. The control plane consists of several
components:

**Kubernetes API Server**

This component acts as a frontend for kubernetes. It receives and validates requests from all cluster
components and users and processes them. Eg.- Desired number of pods is 3 but there are only 2 running. 
Controller requests API server to create a new pod object.

**Controller Manager**

This is a control loop that watches the shared state(etcd) of the cluster via the API server. It's main job is to compare
actual and desired state of the cluster. If there is a difference, it takes corrective action to bring
the cluster back to the desired state. Controller is generally designed to watch a specific type of
object/state and take actions based on it. For e.g.-
Node Controller - Responsible for tracking nodes. It takes action when a node becomes unhealthy.
Job Controller - Watches job objects and watches it for completion.

**Scheduler**

It watches for newly created pod objects and then assigns it a node where the containers of pod run.
Which node gets selected for pod placement depends on factors like resource availability and custom
user rules(e.g.- node affinity, taints/tolerations, requested resources).

**Etcd**

Key-Value store which stores the state of the cluster. It's recommended to make it highly available
and fault tolerant by replicating it across multiple nodes. Also, user should always consistently
perform backups in case something goes wrong.


## Worker Nodes

**Kubelet**

The agent that runs on each worker node. It is responsible for maintaining the containers of a pod.
Kubelet is a node-level agent that manages pods and their containers by interacting with the container runtime. It also constantly reports the status of the node
and the pods running on it to the API server.

Flow for creation of a new pod:

1. User requests creation of a new pod `kubectl create -f pod.yaml`
2. API Server intercepts it.
3. Pod object is created.
4. Scheduler notices that no node is assigned to the pod object.
5. Scheduler assigns a node to the pod object.
6. Kubelet on the assigned node notices the new pod object.
7. Kubelet creates the containers of the pod.

**Kube-proxy**

It is responsible for routing traffic in the node.

**Container Runtime**

The software responsible for managing the container lifecycle. Any container runtime that adheres to
the Kubernetes Container Runtime Interface (CRI) can be used. E.g.- containerd, CRI-O etc.

-----------------------------------------------------------------------------------------------------

Let's talk a bit about nodes as well since both control-plane and worker nodes run on it.

Node controller is responsible for keeping the health check of nodes and list of nodes updated. The
following things are constantly tracked:

1. Disk Pressure - Capacity is too low?
2. PID Pressure - Too many processes running?
3. Memory Pressure - Memory is too low?
4. Network Availability - Network is not working?

Tracking health of Worker Nodes with heartbeats:

Kubelet constantly sends heartbeats to the API server to report the status of the node and it's
availability. There are two types of heartbeats:

**Availability**

Node is available and healthy. It updates the lightweight lease object. The default time is 10s. The
object looks like the following:
```
{
  "kind": "Lease",
  "apiVersion": "coordination.k8s.io/v1",
  "metadata": {
    "name": "node-name",
    "namespace": "kube-system",
  ...
  "spec": {
    "holderIdentity": "node-name",
    "leaseDurationSeconds": 10,
    "acquireTime": "2023-01-01T00:00:00Z",
    "renewTime": "2023-01-01T00:00:00Z"
  }
}
```

**Status - Status of Node**

The sends the status of the node such as CPU, memory, and disk usage. Since this object is a bit heavy,
it gets updated every 40s.

**Communication b/w Worker-Nodes and Control-Plan**

Nodes talk to the control plane using secure HTTP connections. This communication is protected using
certificates based on asymmetric encryption. Each node has its own private key and a public key. When a
node joins the cluster, the control plane uses its private key to approve and sign the node’s public
key, creating a certificate. When the node connects to the control plane, it uses this certificate to
prove its identity at the start of the connection. Once verified, the connection is trusted and all
data is exchanged securely.
