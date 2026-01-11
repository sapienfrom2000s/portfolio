---
title: "Kubernetes - Services and Networking"
date: 2026-01-11 04:00:00 +0530
categories: [K8s]
tags: [kubernetes, services, networking]
---

## Premise & Overview

Pods should not be addressed directly by other pods. Although pods can technically communicate using Pod IPs, this is discouraged because pod IPs are ephemeral. Reason: Pods are ephemeral and can be recreated at any time. With every recreation, a pod is not guaranteed to retain the same IP address. Any component referencing pod IPs directly would need to be updated whenever a pod is recreated.This is where services come into play. Services provide a stable IP address and 
DNS name(`<service-name>.<namespace>.svc.cluster.local`) for a set of pods.

A pod has its own private network namespace which is shared by all containers within that pod. 
Containers within the pod can talk to each other using `localhost`. Pod network(cluster network)
handles communication b/w pods(even in case where pods are in different nodes).

### Kube Proxy

Kube Proxy is a network proxy that runs on each node in the cluster. It runs on each node and watches the Kubernetes API server for Service and Endpoint 
changes. It programs the node’s networking stack (iptables or IPVS rules) so that the Linux kernel can route traffic to the correct backend pods. 
kube-proxy itself does not proxy traffic in the data path. Kube Proxy is responsible for implementing the service abstraction in 
Kubernetes. It works at L4.

### How two pods on a different node talk to each other?

1. Let's say pod A is present on node A and pod B is present on node B.
2. Pod A wants to talk to Pod B.
3. Pod A resolves the Service DNS name to a ClusterIP using CoreDNS.
4. Pod A sends traffic to the Service IP.
5. Kernel networking rules installed by kube-proxy select a backend Pod.
6. Traffic is routed to Pod B on node B via the CNI network.
7. Pod B receives the request.

## Services

Services are Kubernetes objects that provide a stable virtual IP and DNS name for accessing a set of pods. Services are
used to expose applications running in a cluster to the outside world and between pods within the same
cluster.

## Ingress && Ingress vs Load Balancer

Ingress exposes HTTP/HTTPS routes to Services in the cluster. It is implemented by an Ingress Controller (such as NGINX or Traefik), which runs as a pod and performs Layer 7 routing. The ingress
controller is typically exposed via a Service (often type LoadBalancer or NodePort), which provides a public IP/hostname. User generally sets up DNS so that host gets mapped to IP.
Ingress object is implemented by Ingress Controller(e.g. - Nginx). Load balancing is provided by
controller itself. The object looks like the following:
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

Load Balancer (object type – LoadBalancer) works at Layer 4, while Ingress operates at Layer 7.
Ingress is more flexible and powerful because it can route traffic based on host, path, headers, and 
query parameters. It also supports TLS termination, authentication, and centralized HTTP/HTTPS routing 
rules.

Load Balancer excels at distributing incoming traffic evenly across multiple nodes, ensuring that no 
single node is overloaded. Because it operates at Layer 4 (TCP/UDP), it provides high performance and 
stability with low processing overhead. It is well-suited for handling large volumes of traffic, 
traffic spikes, and long-lived connections, while requiring minimal configuration to expose services.


## Gateway API

### Problems with Ingress

1. Devs & Infra Engineer ended up editing the same file for routing and cluster policies. This breaks
separation of concerns.
2. Ingress has a lot of missing advanced features. Ingress controllers fixed it by using annotations.
This creates kind of vendor lock as one feature might be supported at one implementation but not at 
another.
3. Only HTTP/HTTPS routing is supported.

In order to fix these issues, Kubernetes introduced the Gateway API

### Solution

1. 3 resources are introduced by k8s: Gateway Class, Gateway, and HTTPRoute.
2. Gateway class is implemented by a Gateway controller (often provided by a cloud vendor or OSS project like Istio, NGINX, or Envoy Gateway).
3. Gateway defines listeners, ports, and TLS configuration, while routing rules are defined separately using Route resources such as HTTPRoute, TCPRoute, and UDPRoute.
4. Routes handle HTTP, HTTPS, TCP, and UDP traffic.

Gateway API is much better version of ingress as it tries to fill up for stuff that ingress
couldn't do.

## Endpoint Slices

Endpoint slices are objects that contain endpoints (IP/hostname) for pods backing a Service,
including port numbers, conditions (ready/serving/terminating), and topology (zone, node, etc.).
