---
title: "Kubernetes - Pods and Containers"
date: 2026-01-01 12:45:00 +0530
categories: [K8s]
tags: [kubernetes, pods, containers]
---

## Container

Container is an instance of image. Image is the binary data that encapsulates an application
and all it's dependencies. An image is built from a Dockerfile. Dockerfile defines how an
image should be built.

### Container Hooks**

1. PostStart - It gets executed immediately after the container is created.
2. PreStop - It gets executed before the container is terminated.

The following hook handlers are supported:
1. Exec - It executes a command inside the container.
2. HTTP - It executes a HTTP request against an endpoint.

## Pod

Pod is a logical wrapper around one or more containers that run together. Inside Pod:
1. Containers share the same network
2. They can share the same storage
3. They can be scaled together

Pod is generally created by a higher level component eg.- Job, Replicaset. Pod is not a real process,
container is though. The job template looks like the following:

```
apiVersion: batch/v1
kind: Job
metadata:
  name: my-job
spec:
  template:
    spec: # -> Pod spec is defined here. This is called pod template <-
      containers:
      - name: my-container
        image: my-image
        command: ["/bin/sh", "-c", "echo Hello World"]
      restartPolicy: Never
```

### Pod Lifecycle

**Pod Phases**
A pod progresses through several distinct phases:

1. Pending: The pod has been accepted by the cluster, but one or more containers aren't ready yet.
2. Running: The pod has been bound to a node, all containers have been created, and at least one
container is still running or starting/restarting.
3. Succeeded: All containers in the pod terminated successfully and won't be restarted.
4. Failed: All containers have terminated, and at least one container terminated with a failure

**Container States**
Within a pod, each container has its own state:

1. Waiting: Container is waiting to start (pulling image, applying secrets, etc.)
2. Running: Container is executing normally
3. Terminated: Container finished execution or failed

**Restart Policies**
Pods have restart policies that determine what happens when containers exit: Always (default),
OnFailure or Never.
The kubelet manages this entire lifecycle, constantly monitoring pod health through liveness and
readiness probes.

**Probes**
Probes are used to check the health of a container. There are three types of probes:

1. Readiness Probe: Checks if the container is ready to serve traffic. If it fails, the container is removed from the service. Maybe the db is down for some reason.
2. Liveness Probe: Checks if the container is running. If it fails, the container is restarted. Useful when the process is alive but unresponsive (deadlock, infinite loop, stuck thread).
3. Startup Probe: Checks if the container is starting up. If it fails, the container is restarted.
This was introduced to tackle issues with slow container startup times. For example, a container might
take a long time to start up due to a slow database connection. This is done only once ie. during the
startup phase

**Init Containers, SideCar Containers and Ephemeral Containers**

**Init Containers**
Run and complete before the main application container starts. This is used for setup tasks that
shouldn't be part of the main image. They run sequentially in the order defined. Example: Copy files 
into a shared folder, or wait 10 seconds for a database to start before your app runs.

**Sidecar Containers**
Run alongside the main container throughout the pod's lifecycle, providing supporting functionality.
They start before the main container and share the same network and storage. Example: A helper 
container that reads your app's log files and sends them somewhere else for storage.

**Ephemeral Containers**
Temporary containers added to a running pod for debugging purposes, they can't be defined in the pod 
spec and don't restart. Added dynamically using `kubectl debug` when you need to troubleshoot a live 
pod. Example: Your app is broken and you add a temporary container to run commands and see what's wrong 
inside the pod.
