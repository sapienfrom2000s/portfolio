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

Container runtime is a software that manages the lifecycle of containers ie.- starting, stopping, restarting the containers.

- Namespaces: isolate PID, network, mount, and user IDs.
- cgroups: limit and account CPU, memory, IO, and PIDs.
- Filesystem mounts: define a container’s view of the filesystem.
- Lifecycle management: start, stop, and track the process.

At this layer there are no images, registries, or build systems—only isolated processes.

## Images and containers

 A container image is a standardized package that includes all of the files, binaries, libraries, and configurations to run a 
 container. Container is running instance of image.

Mapping:
- image → template
- container → running (or stopped) instance

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

## Docker networking

Docker networking is namespace isolation plus virtual switching. Each container gets its own network namespace. Docker connects those namespaces with virtual interfaces and a bridge (by default) and then programs NAT rules for outbound traffic.

Key ideas:
- Every container has its own network stack (interfaces, routes, ports).
- Port publishing (`-p`) is DNAT from host → container.
- Containers can talk to each other by IP on the same user-defined network without publishing ports.

### Network drivers you should know

- `bridge` (default): a virtual switch on one host. Containers get private IPs; outbound traffic is NATed.
- `host`: container shares the host network namespace. No isolation; no port publishing needed.
- `none`: disables networking inside the container.
- `overlay`: spans multiple hosts (Swarm or other orchestration).

### User-defined bridge vs default bridge

Use a user-defined bridge for real apps:
- Built-in DNS based on container name.
- Better isolation and simpler service discovery.
- Cleaner rules than the legacy default bridge.

### Port publishing vs exposing

- `EXPOSE` is documentation in the image. It does not open ports.
- `-p host:container` publishes a port on the host.
- `-P` publishes all exposed ports to random host ports.

### DNS and service discovery

On user-defined networks, Docker runs an internal DNS server. Containers resolve each other by name. This avoids hard-coded IPs and supports moving or recreating containers.

## Docker cheatsheet

### Build and images

- Build an image: `docker build -t myapp:1.0 .`
- List images: `docker images`
- Remove image: `docker rmi myapp:1.0`
- Image history: `docker history myapp:1.0`

### Containers

- Run a container: `docker run --name web -p 8080:80 myapp:1.0`
- Run interactive shell: `docker run -it --rm ubuntu:24.04 bash`
- List running containers: `docker ps`
- List all containers: `docker ps -a`
- Stop/kill: `docker stop web` / `docker kill web`
- Remove container: `docker rm web`
- Logs: `docker logs -f web`
- Exec into container: `docker exec -it web sh`

### Networking

- List networks: `docker network ls`
- Create network: `docker network create app-net`
- Run on network: `docker run --network app-net --name api myapp:1.0`
- Connect/disconnect: `docker network connect app-net web`
- Inspect: `docker network inspect app-net`

### Storage

- List volumes: `docker volume ls`
- Create volume: `docker volume create app-data`
- Use volume: `docker run -v app-data:/var/lib/app myapp:1.0`
- Bind mount: `docker run -v $(pwd):/app myapp:1.0`

### System cleanup

- Remove stopped containers: `docker container prune`
- Remove unused images: `docker image prune -a`
- Remove unused volumes: `docker volume prune`
- Full cleanup: `docker system prune -a`

### Compose (local)

- Start: `docker compose up -d`
- Stop: `docker compose down`
- Logs: `docker compose logs -f`

## Interview Questions

1. Docker default networking
-> By default, Docker uses the `bridge` driver on a single host. Containers get a private IP on a virtual bridge, and outbound traffic is NATed. The default bridge is legacy and lacks built-in DNS by container name, which is why user-defined bridges are preferred for real apps.

2. How to reduce container image size?
-> Use multi-stage builds, copy only the runtime artifacts, and start from minimal base images (distroless or `scratch` when possible). Combine RUN steps, remove build caches, and avoid adding tools you don’t need at runtime.

3. What’s the difference between CMD and ENTRYPOINT in a Dockerfile?
-> `ENTRYPOINT` sets the fixed executable for the container. `CMD` provides default arguments or a default command that can be overridden at runtime. When both are set, `CMD` usually supplies arguments to `ENTRYPOINT`.

4. What does `docker --init` do?
-> docker init sets up Docker files in your project repo. It scans your app and then generates starter files like a Dockerfile, docker-compose.yml, and .dockerignore. The goal is to help you quickly containerize an existing project without writing everything from scratch. It doesn’t run containers — it just prepares the repo to use Docker easily.

5. Explain docker architecture.
-> Docker uses a client–server architecture.
The Docker Client (CLI) sends commands like build and run to the Docker Daemon.
The Docker Daemon builds images, runs containers, and manages networks & volumes.
Docker Images are read-only templates used to create containers.
Containers are lightweight, isolated runtime instances sharing the host OS kernel.

6. What is docker swarm
-> Docker Swarm is a way to run and manage Docker containers on multiple machines together as one system. Instead of manually starting containers on each machine, you tell Swarm what you want to run and how many copies you need. Swarm then spreads the containers across machines, keeps them running, and shifts them if a machine fails. This makes running apps at scale easier and more reliable.

7. Explain docker compose
-> Docker Compose is a tool used to run multiple containers together on a single machine using one configuration file. You describe your app’s services, networks, and volumes in a simple YAML file, and then start everything with a single command. It’s mainly used for local development and testing because it’s easy to set up and understand. Compose makes sure all containers start in the right order and can talk to each other.

8. Explain lifecycle of docker
-> The Docker lifecycle starts with building an image from a Dockerfile, which defines how the app and its dependencies are packaged. That image is stored locally or pushed to a registry like Docker Hub. Next, the image is used to create and run a container, which is the live, running instance of the app. The container can be started, stopped, restarted, or scaled, and Docker monitors it while running. Finally, containers and images can be stopped, removed, or updated when no longer needed.

9. How to delete an image from local
-> docker image rm <image_id>

10. Can a container restart itself?
-> Yes, a container can restart itself if it crashes or stops unexpectedly. This is controlled by the restart policy set when the container is created. The default policy is "no", which means the container will not restart automatically. Other policies include "always", "on-failure", and "unless-stopped".

12. What are dangling images?
-> Dangling images are images that have no tag or name associated with them. They are created when you build an image without specifying a tag or name, or when you build an image with a tag that already exists. Dangling images can take up space on your system and should be cleaned up periodically.

13. Pruning stuff
-> docker image prune
-> docker network prune
-> docker volume prune
-> docker container prune
-> docker system prune -> combines all above

14. COPY vs ADD. Which one to use?
-> COPY just supports copying local files. ADD supports copying local files, remote files, and archives. Docker's official documentation recommends using COPY for 
most cases. Reserve ADD only for scenarios where you specifically need its unique, automatic tar extraction capability for a local file.

15. How to inspect an image?
->  docker image inspect <image_id>

16. How to make build size smaller?
-> 1. Use multi-stage builds to reduce the size of your final image.
   2. Use a base image that is as small as possible.
   3. Remove unnecessary files and dependencies.
   4. Use a smaller version of the programming language or framework.
   5. Use a smaller version of the operating system.
   6. Use distroless images.

17. How to create custom network? What network driver is used by default?
-> docker network create --driver bridge my_network. Bridge network is used by default.

18. You're working on a critical application running in Docker containers, and an update needs to be applied without risking
    data loss. How do you update a docker container w/o losing data?
-> Will take the backup of the data before updating the container. We will try to create similar setup in some env.

19. How to detach and reattach a container?
-> docker stop my_container
   docker rm my_container
   docker run -d --name my_container \
    -v my_volume:/app/data my_image

20. How do you secure docker containers?
-> Use minimal base images (alpine/distroless)
  Scan images for vulnerabilities (Trivy, Grype)
  Pin image versions, never use latest
  Run containers as non-root users
  Sign and verify images (Docker Content Trust / Cosign)

21. Best practices for managing Docker images and containers
->  Use small, trusted base images and multi-stage builds
    Tag and version images clearly; avoid latest
    Clean up unused images, containers, and volumes regularly
    Run containers with least privilege (non-root, limited resources)
    Monitor, scan, and log containers in production

22. How do you remove a running container?
-> docker stop my_container
   docker rm my_container

23. Various states of docker container at any given point in time?
->  running, paused, restarting, exited

24. Docker volume vs Bind mounts
-> Docker volumes are managed by Docker and are isolated from the host filesystem, while bind mounts are directly mapped to the host filesystem. Docker volumes are more secure and easier to manage, but bind mounts are more flexible and can be used to share data between containers.
Isolation means Docker controls where and how the data is stored, and containers can access it only through the mounted volume—not the host filesystem directly.

25. Talk a bit about namespaces.
-> namespaces is a linux feature which ensures that a process is never able to see the host. It has it's own networking, processes, hosts among other things.
