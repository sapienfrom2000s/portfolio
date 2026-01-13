---
title: "Understanding & Deploying Loki"
date: 2025-11-29 12:00:00 +0000
categories: [loki, devops]
tags: [loki, promtail, kubernetes, logging, devops]
---

### Motivation

As systems grow, logs become huge. Many logging tools stay fast by indexing every word in the logs, but that 
index needs a lot of storage and compute, which makes costs jump. Loki avoids that by indexing only labels 
(like service and environment), so it stays cheaper while still letting you filter and search logs.

### Intro

Loki is a Prometheus-inspired logging system that collects logs from targets (apps, servers, Kubernetes workloads, etc.). It scales horizontally by adding more nodes.

### High level architecture

<img src="{{site.baseurl}}/assets/img/loki-high-level-architecture.png">

Agent is responsible to push logs to Loki. Loki is responsible to process and store
the logs. The logs can be then queried through a frontend(eg.- Grafana).

### Architecture

<img src="{{site.baseurl}}/assets/img/loki-data-flow.png">

Loki is a horizontally scalable logging system made up of microservices. It has support
for multiple remote storage backends such as s3, azure blob store and so on to store logs.

<img src="{{site.baseurl}}/assets/img/loki-index-and-chunks.png">
  
The logs itself has two parts according to loki - index and chunks. Index is prepared from labels and chunks are
the actual logs. Index is stored in a special format called TSDB which is efficient and faster than the
old boltdb-shipper.

**Components**

Distributor – Takes in logs from the agent (/push), validates and distributes streams to ingesters using the hash ring + replication.

Ingester – Buffers logs in memory, builds/compresses chunks, and flushes to long-term storage periodically. Logs are replicated to multiple ingesters for redundancy. Ingester nodes participate in the consistent-hash ring for scalability and availability.

Query UI - May not be part of loki. This is the place from where request is triggered. Eg.- Grafana

Query Frontend(optional) – Improves query performance and stability by splitting queries and passing
to query scheduler or querier. Also, does caching of results whenever possible.

Query Scheduler (optional) – Adds a central queue between query-frontend and queriers.

Querier – Executes LogQL queries by reading recent data from ingesters and historical data from storage/index, then merges results and returns them to the query frontend.

Index Gateway – A dedicated service that serves index data (commonly when index lives in object storage, e.g., TSDB index). It reduces duplicated index fetching and improves query efficiency at scale.

Compactor – It runs in the background to merge small index files into bigger ones and clean up old data so storage stays organized and queries stay fast.

Ruler – Evaluates log-based alerting/recording rules (LogQL) on a schedule and sends alerts to Alertmanager (or the configured alerting path).

**Write Path**

(from docs)
1. The distributor receives an HTTP POST request with streams and log lines.
2. The distributor hashes each stream contained in the request so it can determine the ingester instance to which it needs to be sent based on the information from the consistent hash ring.
3. The distributor sends each stream to the appropriate ingester and its replicas (based on the configured replication factor).
4. The ingester receives the stream with log lines and creates a chunk or appends to an existing chunk for the stream’s data. A chunk is unique per tenant and per label set.
5. The ingester acknowledges the write.
6. The distributor waits for a majority (quorum) of the ingesters to acknowledge their writes.
7. The distributor responds with a success (2xx status code) in case it received at least a quorum of acknowledged writes. or with an error (4xx or 5xx status code) in case write operations failed.

**Read Path**

(from docs)
1. The query frontend receives an HTTP GET request with a LogQL query.
2. The query frontend splits the query into sub-queries and passes them to the query scheduler.
3. The querier pulls sub-queries from the scheduler.
4. The querier passes the query to all ingesters for in-memory data.
5. The ingesters return in-memory data matching the query, if any.
6. The querier lazily loads data from the backing store and runs the query against it if ingesters returned no or insufficient data.
7. The querier iterates over all received data and deduplicates, returning the result of the sub-query to the query frontend.
8. The query frontend waits for all sub-queries of a query to be finished and returned by the queriers.
9. The query frontend merges the individual results into a final result and return it to the client.


### Deployment Modes
- Monolithic Mode - The entire loki is deployed as a single binary object. This is hard to scale.
- Microservices Mode - The components are deployed individually so you can scale different components according to the need.
- Simple Scalable - Middle ground between monolithic and microservices. Components are clubbed and made into a single component and then deployed individually. Distributor and Ingestor becomes one - *write*, querier and query frontend becomes one - *read* and Compactor, Index Gateway, Query Scheduler and Ruler becomes one - *backend*.

Note: UI(eg.- Grafana) and the agent(eg.- promtail) is not part of loki.

--To be Added--
