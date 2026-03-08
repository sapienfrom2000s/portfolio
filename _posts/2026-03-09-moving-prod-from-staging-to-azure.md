---
title: "Prod Migration"
date: 2026-03-07 05:00:00 +0530
categories: [Gcloud, Azure, Prod Migration]
tags: [Gcloud, Azure, Prod Migration]
---

# Migrating a Production Kubernetes Workload from GCP to Azure

After running our infrastructure on Google Cloud for years, we recently completed a full production migration to Azure. This post walks through the phased approach we took — from initial setup and replication to DNS cutover and post-migration cleanup.

The migration involved Kubernetes workloads managed with ArgoCD, MySQL and PostgreSQL databases, and several supporting services. Here's how we did it without significant downtime.

---

## Why a Phased Migration?

Moving production infrastructure isn't a single event — it's a sequence of careful steps. A phased approach lets you:

- Validate each layer independently before proceeding
- Maintain a rollback path throughout most of the process
- Isolate the blast radius if something goes wrong
- Minimise user-facing downtime to a short, controlled window

We structured the migration into 11 stages, though not all were blocking — some ran in parallel.

---

## Stage 1: Kubernetes Configuration & Traffic Split

Before touching production, we set up the groundwork in staging and prepared two independent Kubernetes deployment directories in our GitOps repo (managed with ArgoCD).

Two directories, two clusters:
- `prod-gcp/` — pointed to the existing GCP cluster
- `prod-azure/` — pointed to the new Azure cluster

This made it possible to deploy and manage each environment independently, and merge credentials as a separate, reviewable PR.

Initial config for the Azure directory:
- Delayed jobs and Clockwork replicas set to `0` (no background processing yet)
- Node affinity configured for the new node pool
- Database credentials left unchanged (still pointing to GCP DBs temporarily)
- Replica counts kept at minimum

We split the Kubernetes changes into two PRs:
1. PR-Main — structural changes (directories, node affinity, replica counts)
2. PR-Creds — new Azure database credentials, kept separate for security review and to be merged only at cutover

This separation is a pattern we'd recommend: keep credential changes isolated so they can be merged atomically at the right moment.

---

## Stage 2: Database Replication

With the cluster config ready, we started replicating our databases from GCP to Azure.

Databases involved:
- PostgreSQL (analytics)
- PostgreSQL (Metabase) — *Note: logical replication wasn't viable here due to schema differences, so we took a manual dump (~1.3 GiB) and restored it on Azure*
- MySQL (application DB)

Cross-cloud whitelisting:
An often-overlooked step — both the GCP and Azure database instances needed to whitelist each other's Kubernetes Load Balancer IPs. We did this for both MySQL and PostgreSQL on both sides before any replication started.

---

## Stage 3: Azure Cluster Validation

Once replication was underway, we stood up the Azure cluster fully and validated it:

1. Created the ArgoCD application pointing to `prod-azure/`
2. Verified all services came up healthy
3. Confirmed workloads were still connected to GCP databases (intentionally — replication was still catching up)

MySQL server parameter changes on Azure:
Two parameters needed to be adjusted for compatibility:
- `require_ssl` → disabled (handled at the application layer)
- `sql_mode` → removed `ONLY_FULL_GROUP_BY` (our queries relied on non-standard GROUP BY behaviour)

This is the kind of thing that only surfaces when you actually run your app against the new DB — test early.

---

## Stage 4: DNS Cutover (The Critical Stage)

This was the only stage with planned downtime. We kept the window as short as possible.

Pre-cutover:
- Scaled up node count on Azure to handle full production traffic
- Added a DNS record (via our DNS provider) pointing to the Azure cluster, alongside the existing GCP record, to begin traffic distribution

Cutover sequence:
1. Scaled replicas to `0` on both clusters — downtime begins
2. Initiated database cutover for both MySQL and PostgreSQL (promoting Azure replicas)
3. Merged the credentials PR (PR-Creds) to switch the app to Azure DBs
4. Waited for cutover to complete and replication lag to drain
5. Scaled replicas back up on Azure

Validation checklist post-cutover:
- Main dashboard loads
- Homepage actions functional
- Org chart renders correctly
- Reporting queries return data
- Rich text editor (1:1s) works end-to-end

DNS propagation was monitored and confirmed before declaring success.

---

## Stage 5: Migrating Supporting Services (Metabase)

With the core application stable on Azure, we moved Metabase — our internal analytics and reporting tool.

Steps:
1. Deleted the Metabase app from the old ArgoCD instance
2. Created a MySQL read replica on Azure for Metabase to use
3. Created a new Metabase app in the Azure ArgoCD instance
4. Updated Kubernetes secrets with the read replica credentials
5. Updated the database connection inside Metabase's own settings UI
6. Verified that customer-facing reports were loading correctly

Having a read replica for Metabase is good practice regardless — it keeps analytical queries off your primary DB.

---

## Stage 6: Monitoring & Logging

With the application stable, we set up observability across all environments — production, staging, and regional clusters.

Stack:
- kube-prometheus-stack — metrics collection and alerting via Prometheus, dashboards via Grafana
- Loki — log aggregation
- Promtail — log shipping agent, deployed as a DaemonSet to collect logs from all pods

This combination gives us a fully self-hosted observability stack with no external SaaS dependency. Promtail tails container logs and ships them to Loki, which Grafana queries alongside Prometheus metrics — so you can correlate a spike in error rate with the exact log lines that caused it, in one place.

## Stage 7: Console Access via Master Server

Console access through the master server was restored and verified on Azure. No changes to the access pattern were needed — just ensuring the new cluster nodes were reachable through the existing bastion setup.

---

## Key Takeaways

1. Separate your PRs by concern.
Keeping structural changes separate from credential changes makes review easier and lets you control exactly when secrets go live.

2. Replicate before you cut over.
Starting database replication early gives you time to validate data consistency and iron out issues (like the Metabase dump-and-restore) without time pressure.

3. Whitelist early.
Cross-cloud networking rules are easy to forget and slow to debug. Set them up before you need them.

4. Keep background workers off until you're ready.
Setting delayed jobs and scheduled workers to 0 replicas in the new cluster prevents duplicate job execution during the transition period.

5. Validate at the application layer, not just the infra layer.
Database parameter differences (SSL, `sql_mode`) only surface when your actual app runs against the new instance. Don't skip functional testing.

6. Invest in observability before you need it.
Having Prometheus, Loki, and Promtail in place across all environments means you can correlate metrics and logs in one place — invaluable when debugging issues in a freshly migrated cluster.

---

The migration took several sprints to complete fully, but the phased approach meant we could ship incrementally and keep risk contained. The actual user-facing downtime was limited to the cutover window in Stage 4 — everything else was invisible to users.

If you're planning a similar cloud-to-cloud migration, feel free to reach out or leave a comment below.
