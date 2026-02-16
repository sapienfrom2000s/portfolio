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
