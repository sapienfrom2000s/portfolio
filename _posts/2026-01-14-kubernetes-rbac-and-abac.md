---
title: "Kubernetes: RBAC and ABAC"
date: 2026-01-14
categories: [Kubernetes]
tags: [kubernetes, rbac, abac]
---

## Motivation: Why Authorization Matters

Kubernetes is fundamentally an API-driven system.
Every action such as creating a Pod, reading a Secret, scaling a Deployment is an API request to the kube-apiserver.

In a single-user setup, unrestricted access may appear harmless.
In real systems, clusters are shared by multiple teams, automation, and platform tooling.

Without proper authorization:
- Any identity can perform destructive actions
- Mistakes have cluster-wide impact
- Security boundaries do not exist

Authorization answers a simple but critical question:

> Is this authenticated identity allowed to perform this action on this resource?

Kubernetes supports multiple authorization modes.
The two most important are ABAC and RBAC.

---

## Authentication vs Authorization

- Authentication: Who are you?
- Authorization: What are you allowed to do?

RBAC and ABAC are authorization mechanisms only.
They are evaluated after authentication succeeds.

---

## ABAC: Attribute-Based Access Control

### What Is ABAC?

ABAC makes authorization decisions based on attributes such as:
- User identity
- Resource type
- Namespace
- Request verb

In Kubernetes, ABAC rules are defined in a static policy file on the API server.

### Example ABAC Policy

```json
{
  "apiVersion": "abac.authorization.kubernetes.io/v1beta1",
  "kind": "Policy",
  "spec": {
    "user": "alice",
    "namespace": "dev",
    "resource": "pods",
    "readonly": true
  }
}
```

This allows user alice to read Pods in the dev namespace.

### Limitations of ABAC

- Policies are static files
- Changes require API server restart
- Hard to audit and reason about
- No reuse or delegation model
- Poor scalability

ABAC is largely considered legacy in Kubernetes.

---

## RBAC: Role-Based Access Control

### What Is RBAC?

RBAC introduces a structured, API-native authorization model.
Permissions are defined separately from the identities that use them.

RBAC is built around roles and bindings.

---

## RBAC Core Objects

### Role (Namespace-scoped)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: dev
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

### RoleBinding

RoleBinding connects a Role to one or more subjects(user, group, or service account) in the same namespace.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: dev
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

---

### ClusterRole

ClusterRole defines permissions at the cluster level and for non-namespaced resources.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list"]
```

### ClusterRoleBinding

ClusterRoleBinding connects a ClusterRole to subjects(user, group, or service account) across the cluster.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-node-access
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

tldr;

Subject + Role = RoleBinding                 -> Namespace Scoped
Subject + ClusterRole = ClusterRoleBinding   -> Cluster Scoped

Subject can be user, group or service account

RBAC is used in modern systems as it's easier to maintain than ABAC.
