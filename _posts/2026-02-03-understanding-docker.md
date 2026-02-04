---
title: "Understanding Docker"
date: 2026-02-03 13:00:00 +0530
categories: [Docker]
tags: [docker]
---

# Understanding Docker: from machines to containers

## Motivation

Shipping software should be predictable across laptops, servers, and clouds. Containers solve this by packaging the app and its user‑space dependencies while sharing the host kernel. That gives a repeatable runtime without the weight of a full VM.

## Road to containers

### Bare metal deployment

Physical hardware runs one OS, which runs multiple apps.

Problems:
- Dependency conflicts between apps.
- Poor resource utilization when apps are unevenly loaded.
- Weak isolation; failures leak across processes.

### Virtual machines

A hypervisor runs multiple guest OS instances on one host.

Benefits over bare metal:
- Strong isolation with separate kernels.
- Fewer dependency conflicts per app.
- Better resource utilization via consolidation.
- Faster recreate/rollback compared to reimaging hardware.

### Containers

Containers share the host kernel and isolate processes with kernel primitives.

Compared to VMs:
- Lower overhead (no guest kernel).
- Faster start/stop and smaller images.
- Comparable packaging for dependencies.
- Slightly weaker isolation than separate kernels.

A common production stack combines these layers:

physical host → hypervisor → guest OS → container runtime → app

## Hypervisors: Type 1 vs Type 2

A hypervisor lets multiple OS instances share a host.

- Type 1 (bare metal) runs directly on hardware and controls CPU, memory, and devices.
- Type 2 runs as an app on a host OS, adding extra overhead.

Type 1 hypervisors are standard in data centers and cloud platforms because they are more efficient and offer stronger isolation. This is not the same as dual‑boot; all guests run concurrently.

## What a container runtime actually does

A container is a regular OS process started under a constrained execution context. The runtime sets up that context using Linux kernel primitives:

- Namespaces: isolate PID, network, mount, IPC, UTS, and user IDs.
- cgroups: limit and account CPU, memory, IO, and PIDs.
- Filesystem mounts: define a container’s view of the filesystem.
- Lifecycle management: start, stop, and track the process.

At this layer there are no images, registries, or build systems—only isolated processes.

## Images and containers

An image is an immutable filesystem snapshot plus metadata (env, entrypoint, user, working directory). A container is a runtime instance with a writable layer on top of that image.

Mapping:
- image → template
- container → running (or stopped) instance

Multiple containers can share the same image layers without duplication.

## Why OCI exists

Early container tooling created incompatible image formats and runtime configs. This made ecosystems sticky and hard to mix and match.

The Open Container Initiative (OCI) defines vendor‑neutral specifications so tools interoperate. OCI defines contracts; it does not ship implementations.

OCI specs:
- Runtime Specification: how a container is executed (config.json, namespaces, cgroups, mounts, lifecycle).
- Image Specification: image layout, layers, manifests, and content‑addressable storage.
- Distribution Specification: registry APIs, push/pull semantics, auth flows.

## Runtimes in practice

There are layers of responsibility:

- Low‑level runtime: executes a container per OCI Runtime Spec. Example: runC.
- Container manager: manages images, snapshots, and lifecycle at scale. Examples: containerd, CRI‑O.
- Developer platform: builds images, manages networks/volumes, and provides CLI/UX. Examples: Docker, Podman.

Docker uses containerd internally; Docker is not a standard and is not required to run containers.

## Core Linux primitives

### Namespaces

Namespaces isolate a resource so processes see a restricted view:

- PID: processes see their own PID tree; the first process appears as PID 1.
- Network: isolated interfaces, routes, firewall rules, and ports.
- Mount: container mount operations do not affect the host.
- UTS: hostname and domain isolation.
- IPC: isolated shared memory and message queues.
- User: UID/GID remapping enables root inside, non‑root outside.

### cgroups

cgroups control resource usage:

- CPU: shares, quotas, and scheduling priority.
- Memory: limits and OOM behavior.
- Block IO: throughput and IOPS control.
- PIDs: process count limits.

### Union filesystems (OverlayFS)

OverlayFS composes multiple read‑only layers with a writable layer:

- Lower layers: image layers (shared, read‑only).
- Upper layer: container‑specific writes.
- Merged view: the filesystem exposed to the container.

Copy‑on‑write keeps images immutable while allowing runtime changes.

## Storage: bind mounts vs volumes

Both are mounted into the container’s mount namespace, but they differ in ownership and lifecycle.

- Bind mounts map a host path into a container. Simple and fast, but tied to host layout and permissions.
- Volumes are managed by the runtime and referenced by name. They persist independently of containers and are more portable.

Use bind mounts for local development; use volumes for production data.

## Image layering

Each Dockerfile instruction creates a new immutable layer. Layers are cached and shared across images. When a container runs, Docker adds a thin writable layer on top. All runtime changes go to that layer and are discarded when the container is removed.

## Container flags you’ll see often

- `--tty` (`-t`): allocate a TTY.
- `-i`: keep STDIN open.
- `-it`: interactive shell.
- `--rm`: delete the container on exit.
- `docker start`: start a stopped container.
- `docker attach`: attach to a running container’s STDOUT/STDERR.

## Privileged and host‑shared modes

- `--privileged`: grants near‑host access; disables most isolation.
- `--pid=host`: share the host PID namespace; container sees host processes.

These are powerful and risky; use only when needed.

## Minimal images and `scratch`

Containers do not need a full distro. The kernel is provided by the host; the image only needs user‑space files. `FROM scratch` creates an empty filesystem. Statically linked binaries (for example, Go) can run directly with no shell or libc in the image.

## Multi‑stage builds

Multi‑stage builds separate build‑time tools from runtime output. You compile in one stage, then copy only the artifacts into a minimal final image.

Example (Go):

```dockerfile
# Build stage
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app

# Runtime stage
FROM scratch
COPY --from=builder /app/app /app
CMD ["/app"]
```

Example (Node.js):

```dockerfile
# Build stage
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Runtime stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
```

Only the final stage ships to production.

## Orchestration on one host vs a cluster

- Docker Compose defines multi‑container apps on a single host with a `docker-compose.yml` file.
- Docker Swarm runs services across multiple hosts with replication and rolling updates.

## ENTRYPOINT vs CMD

`ENTRYPOINT` defines the primary executable. `CMD` provides default arguments or a default command that can be overridden at runtime. Use `ENTRYPOINT` for the fixed binary and `CMD` for defaults.
