---
title: "AWS - Interview Questions"
date: 2027-01-14
categories: [AWS]
tags: [AWS]
---

Q. What is SCP?
A. A Service Control Policy in Amazon Web Services Organizations sets the maximum permissions for 
accounts within an organization. It does not grant 
permissions; it only restricts them. Even if an Identity and Access Management policy allows an action, 
if the Service Control Policy denies it, the 
action is denied. For example, they can be used to block access to specific Amazon Web Services regions 
or prevent the deletion of critical services 
across all accounts.

Q. What is a route table?
A. A route table is a data structure maintained by a router, host, or network device that defines how 
IP packets are forwarded between networks. It contains entries that map destination IP address prefixes 
(defined using CIDR notation) to a next-hop IP address, outgoing interface, and associated metrics used 
to determine route preference. When a packet arrives, the device performs a longest-prefix match lookup 
against the routing table to identify the most specific route for the destination IP address, then 
forwards the packet accordingly. Route tables can contain both static routes configured manually and 
dynamic routes learned through routing protocols such as OSPF, BGP, or RIP, and they are fundamental to 
Layer 3 (network layer) packet forwarding in IP-based networks. IP route can be viewed using the 
command `ip route show` or `route -n`.

Q. What is ARP and IP table?
A. The ARP table and IP (routing) table serve different purposes at different OSI layers.

The ARP table (Layer 2) stores mappings of IP addresses to MAC addresses within a local network. It is used to resolve an IP address to a MAC address so a device can deliver frames on the same subnet.

The IP routing table (Layer 3) determines how packets are forwarded between networks. It maps destination IP prefixes to a next-hop gateway and interface, using longest-prefix match to select the best route.

Q. Internet Gateway vs NAT Gateway
A. Internet Gateway (IGW) allows bidirectional communication between your VPC and the internet. 
Resources in a public subnet need a public IP and route table entry (0.0.0.0/0 → IGW). Example: A web 
server at 54.123.45.67 receives HTTP requests from users and sends responses back. It's stateless, 
managed by AWS, and free. Use it when resources must be directly accessible from the internet - web 
servers, bastion hosts, public APIs.
NAT Gateway provides outbound-only internet access for private subnets. It lives in a public subnet 
with an Elastic IP, while private subnets route internet traffic (0.0.0.0/0 → NAT-GW). Example: A 
database at 10.0.2.50 (no public IP) downloads security patches or your backend calls external APIs, 
but the database cannot receive inbound connections from the internet. It's stateful (tracks connections
), highly available within an AZ, and costs ~$0.045/hour plus data transfer.
Production setup uses both: Public subnet has ALB/web tier with IGW for user-facing traffic. Private 
subnet has databases/app servers using NAT Gateway for outbound-only access (OS updates, third-party 
API calls, AWS service endpoints). This follows security best practice - minimize attack surface by 
keeping backend infrastructure inaccessible while allowing necessary outbound connectivity. Key 
difference: IGW = two-way, resources exposed; NAT Gateway = one-way out, resources hidden.

Q. NFS vs EFS vs EBS
A. NFS: Protocol for sharing filesystems over network; supports multi-client concurrent access with distributed locking; performance degraded by 
network latency (milliseconds); requires managing your own NFS server infrastructure; flexible but 
operationally complex.

EBS: Block storage attached to single EC2 instance; sub-millisecond latency with predictable IOPS/throughput;
; automatic AZ replication; single-writer limitation (one instance at a time); ideal for databases, boot volumes, and high-performance 
single-instance workloads.

EFS: AWS-managed NFS service (NFSv4.1); elastic scaling without provisioning; multi-AZ durability with concurrent multi-instance access; higher 
latency than EBS (single-digit milliseconds); expensive for throughput-intensive workloads; perfect for shared content repositories, home 
directories, and containerized applications needing shared storage.
Choose EBS for single-instance performance-critical apps, EFS when multiple instances need shared access, self-managed NFS when you need custom 
configurations or non-AWS environments.

Q. NLB vs ALB
A. The main difference is that ALB works at Layer 7 and NLB works at Layer 4.
ALB understands HTTP/HTTPS traffic and can do path-based and host-based routing, so it's ideal for web applications and microservices.
NLB works at the transport layer and handles TCP/UDP traffic. It’s designed for very high performance and low latency, and it supports static IP addresses.
So for HTTP-based apps I’d use ALB, and for high-performance TCP/UDP workloads or when I need static IP, I’d use NLB.

Q. You have a EC2 machine. You want the machine to be able to be able to talk to the internet. What
security group rules will be applied? Do we need inbound rule because data will be received from the 
internet? If no, why no?
A. Outbound rule - Allow all traffic to the internet. 0.0.0.0/0, HTTP
No inbound rule is needed because traffic going out of SG is stateful. It remembers the connection and 
allows the response traffic to flow back in.
NACL on the other hand is stateless.

Q. What does your typical day looks like?
A. I primarily work on backend features. However, since I also understand our infrastructure well, I often get involved when infra issues arise. A part of my day can shift toward
debugging infra-related problems, migrations, or stabilizing environments. So my role ends up being a mix of feature development and operational problem-solving.

Q. How would you architect a fully available, fault tolerant, scalable, and secure architecture for a web application?
A. 
Edge — CDN + WAF (DDoS protection, caching, geo-routing)
Load Balancing — ALB/NLB across multiple AZs, health checks, auto-scaling trigger
Compute — Stateless app servers in private subnets, auto-scaling groups (or containers via ECS/K8s)
Data — Managed DB with Multi-AZ failover + read replicas + cache layer (Redis)
Foundation — VPC, IAM, encryption, IaC, observability

Edge Layer
"At the edge, my primary goals are reducing latency, absorbing attack traffic before it hits my infrastructure, and enabling global availability."

CDN: I'd use CloudFront or Cloudflare to cache static assets and offload origin. But beyond caching, I'd use it for geo-routing — routing users to the 
nearest healthy region. Key decision here is cache invalidation strategy: TTL-based for most assets, explicit invalidation for deployments.

WAF: Sits in front of CDN. I'd configure OWASP top 10 rules, rate limiting per IP, and geo-blocking if the business doesn't operate in certain regions. 
Important — WAF rules need tuning; out-of-the-box managed rules will false-positive in production, so you start in count mode, analyze logs, then switch 
to block mode.

DDoS: At this layer I'd rely on Shield Standard (free) or Shield Advanced for volumetric attacks. The CDN itself absorbs a lot — if you're serving cached 
responses, origin never sees the flood.

DNS: Route53 with health checks and latency-based or failover routing policies. This is where multi-region failover lives — if primary region health check 
fails, Route53 automatically routes to secondary. RTO here can be under 60 seconds.
What breaks it: Cache poisoning, misconfigured TTLs serving stale data post-deploy, WAF rules blocking legitimate traffic. I've seen deployments go wrong because engineers forgot to invalidate CDN cache — users got old JS for hours.

Load Balancing Layer
"Here I'm solving for fault tolerance within a region and being the entry point for auto-scaling decisions."
ALB vs NLB: ALB (L7) for HTTP/HTTPS traffic — gives me path-based routing, host-based routing, and can inspect headers. NLB (L4) for ultra-low latency or 
non-HTTP protocols like WebSockets at scale or TCP. For most web apps, ALB is the right default.
Multi-AZ: ALB spans multiple AZs automatically, but I need to ensure my target groups have instances in each AZ. I'd enable cross-zone load balancing and 
set deregistration delay appropriately — long enough for in-flight requests to complete, short enough that deployments aren't slow.
Health Checks: This is often underinvested. A shallow health check (/health returns 200) is not enough. I want a deep health check that verifies DB 
connectivity, cache connectivity, and any critical dependency — so the LB only routes to truly healthy instances. But I'd be careful — if the DB goes 
down, I don't want all instances to fail health checks and cause a full outage. So I'd separate liveness from readiness checks.
Auto-scaling trigger: The LB feeds CloudWatch metrics — RequestCount, TargetResponseTime, HealthyHostCount. I'd set auto-scaling policies on these. Target 
tracking on RequestCountPerTarget is usually the right starting point.
What breaks it: Health check misconfiguration is the #1 issue. Either checks are too shallow (routing to broken instances) or too aggressive (flapping 
instances). Also, not accounting for connection draining during deployments causes dropped requests.

Compute Layer
"Statelessness is the non-negotiable principle here. If my instances have state, I can't scale horizontally or recover from failure cleanly."
Stateless design: Sessions go to ElastiCache (Redis), uploaded files go to S3, any shared state goes to the data layer. The instance itself should be disposable — I should be able to terminate any instance at any time without user impact.
Containers vs VMs vs Serverless:

ECS/EKS (containers): My default for most workloads. Faster startup than VMs, better resource utilization, easier to enforce consistency across 
environments.
Auto-scaling groups (VMs): Still valid for workloads that need full OS control or specific compliance requirements.
Lambda (serverless): Great for event-driven, spiky, or low-traffic workloads. I'd avoid it for latency-sensitive, high-throughput APIs because cold starts 
and execution limits become real problems.

Zero-downtime deployments:

Blue/Green: Full parallel environment, instant cutover, easy rollback. Expensive (double infrastructure temporarily).
Canary: Route 5% of traffic to new version, monitor error rates and latency, gradually increase. My preference for high-traffic systems because it limits 
blast radius.
Rolling: Replace instances gradually. Simpler but means two versions run simultaneously — your app needs to be backward compatible.

K8s specifics: If on Kubernetes, I'd set Pod Disruption Budgets to ensure minimum healthy pods during node maintenance, configure resource requests and 
limits properly (without them, you get noisy neighbor problems), and use Horizontal Pod Autoscaler with custom metrics.
Graceful shutdown: Often overlooked. When a container gets a SIGTERM, it should stop accepting new requests, finish in-flight ones, then exit. Without 
this, rolling deployments drop requests.
What breaks it: Stateful instances that can't be terminated, bad resource limits causing OOM kills, deployments without graceful shutdown dropping live 
requests, and not testing auto-scaling — teams set it up and assume it works until it doesn't.

Data Layer
"This is where availability gets hard. Compute is easy to scale — data has gravity, consistency constraints, and failure modes that can cause permanent 
data loss."
Database — Multi-AZ: RDS Multi-AZ gives synchronous replication to a standby — automatic failover in ~60-120 seconds. Aurora is better: shared storage 
layer, failover in ~30 seconds, and up to 15 read replicas. For global, I'd use Aurora Global Database — sub-second replication across regions.
Read replicas: Offload read traffic from primary. But important caveat — replication lag. If my app reads immediately after a write, it might read stale 
data from a replica. I'd design around this: either route writes and immediate-read-after-writes to primary, or use read-your-writes consistency patterns.
CAP Theorem in practice: For most web apps, I choose CP (consistency over availability) for financial or critical data, and AP (availability over 
consistency) for things like user feeds or counters where eventual consistency is acceptable. You need to make this explicit in design — don't stumble 
into it.
Caching with Redis: Cache database query results, computed values, session data. Key decisions: TTL strategy, cache invalidation (hardest problem in CS — 
I'd use write-through or cache-aside pattern depending on read/write ratio), and what happens on cache miss under high load (cache stampede — solve with 
probabilistic early expiration or locking).
Connection pooling: Databases have connection limits. At scale, hundreds of app instances each opening multiple connections will exhaust the DB. I'd use 
PgBouncer for Postgres or RDS Proxy — sits between app and DB, multiplexes connections.
Backup and restore: Backups mean nothing if you've never tested restore. I'd automate restore testing — weekly restore to a test environment, verify data 
integrity. Also point-in-time recovery enabled, and I'd know the RPO (how much data can I lose) and RTO (how fast can I recover) numbers explicitly.
Data tiering: Hot data in primary DB + cache, warm data in S3 with Athena for querying, cold data in Glacier for compliance archival.
What breaks it: Replication lag surprises, connection exhaustion, untested backups, cache stampedes on cold start, and schema migrations without backward 
compatibility causing downtime during deployments.

Foundation Layer
"This is the platform everything runs on. If this is wrong, all the layers above it are insecure, unreliable, or unauditable."
VPC and Network Segmentation:

Public subnets: Only load balancers and NAT gateways. Nothing else.
Private subnets: App servers. Can reach internet via NAT gateway but not reachable from it.
Isolated subnets: Databases. No internet access at all, only accessible from app subnet.
Security groups are stateful firewalls at instance level — least privilege, no 0.0.0.0/0 on sensitive ports. NACLs as a second layer at subnet level.

IAM: Least privilege always. No long-lived access keys — use IAM roles for EC2/ECS/Lambda. For humans, enforce MFA and use SSO. I'd run IAM Access Analyzer continuously to catch overly permissive policies. Service accounts should have only the permissions they need for their specific function.
Secrets Management: No secrets in environment variables, no secrets in code or config files. Everything in AWS Secrets Manager or HashiCorp Vault with automatic rotation. App fetches secrets at runtime.
Encryption: TLS everywhere, even internal service-to-service. Data at rest encrypted with KMS — and I manage key rotation. Don't use default AWS-managed keys for sensitive data; use customer-managed keys so you control rotation and access.
IaC: Everything in Terraform or Pulumi. No manual changes in console — if someone makes a manual change, the next terraform apply will revert it or flag drift. This gives you reproducibility, auditability via Git history, and the ability to spin up identical environments for staging/prod parity.
Observability — the three pillars:

Logs: Structured JSON logs, shipped to centralized store (CloudWatch Logs, Datadog, ELK). Correlation IDs on every request so you can trace a single request across 10 microservices.
Metrics: Infrastructure metrics (CPU, memory, disk) plus application metrics (request rate, error rate, latency — the RED method). Dashboards and alerts on SLOs, not just raw metrics.
Traces: Distributed tracing with X-Ray or Jaeger — essential in microservices to find where latency is actually coming from.



Q. Talk a bit about CAP theorem.
A. Consistency, Availability and Partition Tolerance (CAP). P is non-negotiable as networks are unreliable. It's either C or A.
CP - Consistent systems

In a CP (Consistency + Partition tolerance) system, when a network partition happens, the system prefers to stay consistent even if it has to reject some 
requests, which is achieved using a majority quorum. This is conceptually the same as the rule W + R > N, ensuring read and write operations overlap and 
preventing split-brain. In leaderless databases like Cassandra, you configure N (replicas), W (write quorum), and R (read quorum) directly (e.g., N=5, 
W=3, R=3 for strong consistency). In traditional PostgreSQL (primary-replica), writes go only to the primary, and replicas may serve stale reads if 
replication is asynchronous—there is no explicit W+R control. In distributed SQL systems like CockroachDB, Raft consensus enforces majority agreement 
automatically (e.g., 3 of 5 replicas), ensuring consistent commits and preventing conflicting writes during failures.
Note - Any replica can serve read and write. No separate components.

In an AP (Availability + Partition tolerance) system, when a network partition happens, the system prefers to remain available even if that means 
temporary inconsistencies, so both sides of the partition can continue accepting reads and writes. Unlike CP systems that require a majority quorum, AP 
systems often use smaller quorum settings (e.g., W=1, R=1 with N=5), meaning reads and writes may not overlap, and stale or conflicting data can occur. 
All replicas can handle reads and writes, and there are no fixed read/write nodes. Conflicts are resolved later using mechanisms like last-write-wins, 
vector clocks, CRDTs, or background repair processes. Systems like Cassandra or DynamoDB can behave this way when configured with low consistency levels, 
prioritizing uptime over immediate consistency.


Q. NACL vs Security Groups. When to use each one?
A.

Q. EKS vs ECS vs Docker Container on VM vs VM. When to use each one?
A.

Q. What is the difference between a VPC and a subnet?
A.

Q. What is connection Pooling?
A. Connection pooling is a technique used to improve application performance by maintaining and reusing a fixed set of pre-established connections 
(commonly database connections) instead of creating and closing a new connection for every request, which is expensive due to network handshakes, 
authentication, and resource setup. The application creates the pool (usually at startup) with a configured minimum and maximum number of connections, and 
when a request needs to access the database, it borrows a connection from the pool and returns it after finishing its work; when we say a “connection 
becomes free,” we mean that the request using it has completed and returned it to the pool, making it available for reuse. If the number of concurrent 
users exceeds the number of available connections, no new pool is created; instead, additional requests wait in a queue until a connection is released 
back into the pool, and they proceed once one becomes available. Some pools can grow dynamically up to a defined maximum limit, but beyond that limit, 
requests continue waiting and may eventually fail with a timeout error if a connection does not become available in time, helping protect the database 
from being overwhelmed while ensuring controlled resource usage and better scalability. Connection Pooling is usually handled by the application or the database driver.

Q. Problems with lambda? Why use servers when you can use lambda functions?
A.
