---
title: "Kubernetes - Objects"
date: 2025-12-29 22:00:00 +0530
categories: [K8s, Objects]
tags: [kubernetes]
---

# Overview

Objects tell K8s about the desired state of something. It is generally defined
in YAML(or JSON) format and then is passed to API server as payload using HTTP.
It is stored in etcd store for persistence so that it can be retrieved later if needed.
Every object has two main parts - spec and status. Spec defines the desired state of the object,
while status reflects the current state of the object. Object names(user-defined) are unique per kind
within a namespace, while UIDs are globally unique.

## Top Level Fields

1. apiVersion - The version of the API schema used to define the object. This makes sure that both
                client and server are on the same page. It might look something like `v1`, `v1alpha1` etc.
2. kind - The type of the object. Eg.- `Pod`, `Deployment`, `Service` etc.
3. metadata - It stores the metadata about the object. It can have fields like name, namespace, labels,
              annotations etc.
4. spec - It defines the desired state of the object.

### Sample YAML File

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

## Ways of defining objects

1. Imperative Command - Using kubectl command line tool(`kubectl create deployment nginx-deployment --image=nginx:1.14.2`)
2. Imperative Object Configuration - YAML + Imperative Command(`kubectl create -f nginx-deployment.yaml`)
3. Declarative Object Configuration - Defining everything in file(`kubectl apply -f nginx-deployment.yaml`).
This is the way to go in prod setup as it is git friendly.

## Labels and Selectors

Labels are key-value pairs used to 'label' objects. These are helpful in filtering objects later on. Maybe
you have 5 deployments and 2 are marked as `release: dev`. So now you can target `release: dev` and get only
the relevant deployments. Selectors are used by Kubernetes objects and kubectl commands to match resources
based on labels.

## Namespaces

As described above, object names are unique for a given kind. But it's possible that multiple teams are working
on the same cluster. This increases the chance of name collision. In order to tackle this, namespaces were
created. They allow users to create objects with the same names, scoped to different namespaces, without
stepping on each other’s toes.

Note that some resources are cluster-scoped, meaning namespaces don’t apply to them. Eg - Namespaces, nodes,
ClusterRoles etc.


## Annotations

These are non-identifying(labels are identifying and used for querying) info around objects meant for the
consumption of machines(tools + libraries). It can accomodate more data than labels. Eg.-

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: peoplebox-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
...
```

Annotation vs Label - Annotations configure behavior; labels define identity.

## Field Selectors

Field selectors are used to filter objects based on their fields. Eg.-

```
kubectl get pods --field-selector status.phase=Running
```

## Finalizers, Owners and Dependents

Finalizers are deletion blockers that allow controllers to perform cleanup work before an object is fully removed from the cluster. When an object with finalizers is deleted, Kubernetes sets a deletionTimestamp but does not remove the object until all finalizers are cleared.

Finalizers are identifiers, not a list of objects to delete. They rely on external controllers to observe the deletion and perform the necessary cleanup before removing the finalizer.

```
metadata:
  finalizers:
    - obj1
```

Kubernetes uses ownerReferences to define ownership relationships between objects. This enables cascading deletion, where deleting a parent object automatically deletes its dependents.

A natural hierarchy exists in many built-in workloads. For example:
A Deployment owns one or more ReplicaSets
A ReplicaSet owns the Pods it creates

If an owner object is deleted, Kubernetes garbage collection automatically deletes its dependents.
