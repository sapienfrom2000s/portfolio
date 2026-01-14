---
title: "ConfigMaps & Secrets in Kubernetes"
date: 2026-01-14
categories: [Kubernetes]
tags: [kubernetes, configmap, secrets, devops]
---

# ConfigMaps & Secrets in Kubernetes

## Motivation: Why Do We Even Need ConfigMaps and Secrets?

Imagine building a containerized application that works perfectly on your laptop.
Now deploy the same application to **dev**, **staging**, and **production**.
The problem is:
- Database URLs differ per environment
- Feature flags change frequently
- External service endpoints are not the same 
- Credentials must never be hardcoded

If all this information is baked **inside the container image**, you are forced to:
- Rebuild images for every environment
- Risk leaking credentials into source control

This is the **exact problem** Kubernetes ConfigMaps and Secrets are designed to solve.

> **They decouple application code from configuration and sensitive data.**

---

## The Core Problem They Solve

### Without ConfigMaps & Secrets
- Configuration is hardcoded in images or manifests
- Every config change requires a rebuild
- Secrets may end up in Git repositories
- Deployments become environment-specific

### With ConfigMaps & Secrets
- One image runs everywhere
- Configuration is external and dynamic

---

## What Is a ConfigMap?

A **ConfigMap** is a Kubernetes object used to store **non-sensitive configuration data**.


### Typical Use Cases
- Environment variables (`APP_ENV=prod`)
- Feature flags
- Application config files
- Logging levels and timeouts

### Key Characteristics
- Stores **plain-text** data
- Designed to be **human-readable**
- Can be consumed as:
  - Environment variables
  - Files mounted into containers
  - Command-line arguments

---

## What Is a Secret?

A **Secret** is a Kubernetes object meant to store **sensitive information**.

### Typical Use Cases
- Database passwords
- API tokens
- TLS certificates
- OAuth credentials

### Key Characteristics
- Stored as **base64-encoded values**
- Access is restricted using **RBAC**
- Can be injected as:
  - Environment variables
  - Mounted files
- Integrates well with external secret managers

---

## Why Are Kubernetes Secrets Base64-Encoded?

https://stackoverflow.com/questions/49046439/why-does-k8s-secrets-need-to-be-base64-encoded-when-configmaps-does-not
