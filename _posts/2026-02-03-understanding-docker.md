---
title: "Understanding Docker"
date: 2026-02-03 13:00:00 +0530
categories: [Docker]
tags: [docker]
---

# Motivation

Works on my machine

## Road to containers

### Deploying on Bare Metal

-> Physical Hardware -> OS -> Libraries -> Apps1, Apps2

Problems:
- Dependencies
- Hardware not utilized at full capacity
- Very low isolation - Issues with one application can affect other applications running on the same host

### Deploying on Virtual Machines

-> Physical Hardware -> Virtualization -> OS -> Libraries -> Apps1, Apps2

Benefits over Bare Metal:
1. No dependency conflicts because each VM has its own OS and libraries.
2. Better resource utilization as multiple VMs can run on a single physical machine.
3. Improved isolation as each VM runs in its own virtualized environment ie. Small blast radius.
4. Destroy and recreate VMs quickly without affecting other VMs/apps.


### Containers

-> Hardware -> OS -> Container Runtime -> Libraries -> App1, App2

Containers vs VMs:
1. Less overhead. Doesn't run full fleged OS. Uses host kernel.
2. Containers are more portable and can be easily moved between hosts.
3. No dependency conflicts.
4. Small blast radius.
5. lightweight
6. Quickly run the container and tear it down.
7. Container provides a bit less isolation than VMs.

Cloud running containers combine all of the above(VM + Container + Orchestrator):

-> physical machine -> hypervisor -> OS -> container runtime -> app

## type 1 and type 2 hypervisor

A hypervisor is software that enables multiple operating systems to run on the same physical machine. There are two types of 
hypervisors: Type 1 and Type 2. A Type 1 (bare-metal) hypervisor runs directly on the hardware and functions as a minimal, 
specialized operating system. It boots from BIOS/UEFI just like an OS and controls CPU, memory, and devices. Multiple guest 
operating systems run on top of it at the same time. A Type 2 hypervisor runs as an application on a host operating system. 
Because of the extra OS layer, Type 2 has more overhead and slightly lower performance. Type 1 hypervisors offer stronger 
isolation and better efficiency. They are commonly used in servers and cloud environments. Hypervisors are not the same as 
dual-boot systems, because all guest OSes run concurrently.


# Notes

Docker is a container runtime. There are other container runtimes like Podman, rkt, etc.
Docker image is like a class. Container is like an instance of a class.
Docker vs containerd


Open Container Initiative:
- built to standardize container formats and specifications
- Runtime Specification: Defines how a container should be run
- Image Specification: Defines how a container image should be built
- Distribution Specification: Defines how container images should be distributed


Containers: conceptual layering and standards
1. Container runtime (foundation)

At the lowest useful abstraction, a container runtime is software that executes a process with isolation and resource constraints by configuring Linux kernel primitives:

Namespaces (PID, mount, network, IPC, UTS, user)

cgroups (CPU, memory, IO limits)

Filesystem mounts

Process lifecycle management

A container is therefore not a VM and not an object in itself; it is a regular OS process started under a constrained execution context.
The runtime’s only responsibility is to create and manage that context.

At this layer, there is no notion of:

images

registries

build systems

developer tooling

2. Images and containers

A container image is a filesystem artifact plus metadata:

root filesystem (often layered)

environment variables

entrypoint / command

user, working directory, etc.

An image is immutable.

A container is:

a runtime instance created from an image

a running (or stopped) process with state

backed by a writable layer on top of the image

This maps cleanly to:

image → definition/template

container → runtime instance

Multiple containers can be created from the same image without duplicating underlying layers.

3. The interoperability problem

Early container tooling evolved independently, leading to:

incompatible image formats

runtime-specific configuration

tight coupling between build tools, runtimes, and registries

This created vendor lock-in and made it difficult to swap components.

4. Open Container Initiative (OCI)

The Open Container Initiative (OCI) defines open, vendor-neutral specifications to ensure interoperability across the container ecosystem.

OCI does not provide implementations.
It defines contracts that implementations must follow.

5. OCI specifications
5.1 Runtime Specification

Defines:

how a container is executed

process configuration

namespace and cgroup setup

mount configuration

container lifecycle states

The specification is expressed via a config.json file consumed by the runtime.

Any runtime that implements this spec can execute an OCI-compliant container.

Example implementation:

runC

5.2 Image Specification

Defines:

image layout

layer format

manifests and configuration objects

content-addressable storage

This ensures:

images built by one tool can be run by another

runtimes are decoupled from build systems

5.3 Distribution Specification

Defines:

registry APIs

push/pull semantics

authentication flows

This enables interoperable registries across vendors and platforms.

6. Runtime hierarchy in practice

In real systems, runtimes are layered:

Low-level runtime

Executes containers per OCI runtime spec

Example: runC

Container manager

Manages container lifecycle at scale

Handles image storage, snapshots, and state

Exposes APIs to higher-level systems

Examples: containerd, CRI-O

These managers invoke a low-level runtime to start the actual container process.

7. Docker vs containerd
containerd

A container manager, not a developer tool

Focused on stability and minimal surface area

Implements image management and container lifecycle

Uses an OCI runtime (e.g., runC) underneath

Native runtime for Kubernetes via CRI

Docker

A developer-facing platform

Provides image build, registry interaction, networking, volumes, and CLI UX

Uses containerd internally for container management

Does not define container standards

Docker is therefore not required for running containers; it is one possible tooling layer built on standardized components.

8. Summary model

Linux kernel primitives enable isolation

Container runtimes configure those primitives

Images package filesystems and metadata

OCI standardizes runtime, image, and distribution contracts

runC executes containers

containerd manages containers at scale

Docker and Podman focus on developer experience

This separation allows components to evolve independently while remaining interoperable.

A bit of history:



# Tech Overview

- Namespaces - Allows to isolate system resource inside a jail such that they don't know anything about the world but feels like a fresh instance. Eg.- processes in a container(you can get PID1), networking, etc.
- Control Groups
- Union Mount Filesystem(overlayfs):


Core Linux primitives used by containers
1. Namespaces

Namespaces provide isolation by partitioning global system resources so that a set of processes sees a restricted and independent view of the system. Processes inside a namespace are unaware of resources outside that namespace.

Each namespace type isolates a specific class of resources.

Key namespace types:

PID namespace

Isolates process IDs.

Processes inside the namespace see their own PID tree.

The first process started in a PID namespace appears as PID 1 and assumes init-like responsibilities (signal handling, orphan reaping).

Network namespace

Provides an isolated network stack.

Each namespace has its own interfaces, routing table, firewall rules, and ports.

Enables containers to have independent IP addresses and port spaces.

Mount namespace

Isolates filesystem mount points.

Mount and unmount operations inside the namespace do not affect the host or other containers.

UTS namespace

Isolates hostname and domain name.

Allows containers to define their own host identity.

IPC namespace

Isolates interprocess communication resources such as shared memory, semaphores, and message queues.

User namespace

Isolates user and group IDs.

Allows a process to have root privileges inside the container while being mapped to an unprivileged UID on the host (foundation for rootless containers).

Effect:
Namespaces create the illusion of a dedicated system instance while sharing the same kernel.

2. Control Groups (cgroups)

Control Groups (cgroups) provide resource management and accounting for processes. While namespaces isolate visibility, cgroups isolate resource usage.

Cgroups allow the kernel to:

limit resource consumption

prioritize workloads

account for resource usage

enforce isolation policies

Commonly controlled resources:

CPU

Limits CPU shares, quotas, and scheduling priority.

Memory

Enforces memory limits and triggers OOM handling within the group.

Block I/O

Controls disk throughput and IOPS.

PIDs

Limits the number of processes to prevent fork bombs.

Network (indirectly)

Via traffic shaping mechanisms tied to cgroups.

Each container typically runs inside its own cgroup subtree.

Effect:
Cgroups prevent containers from monopolizing host resources and provide predictable performance boundaries.

3. Union Mount Filesystems (OverlayFS)

A Union Mount Filesystem allows multiple filesystems to be layered and presented as a single unified filesystem.

In containers, this is commonly implemented using OverlayFS.

OverlayFS structure:

Lower layers

Read-only layers

Represent image layers

Shared across containers

Upper layer

Writable layer

Container-specific

Captures all filesystem changes made by the container

Merged view

The unified filesystem presented to the container process

Key properties:

Changes in a container do not modify the underlying image layers.

Multiple containers can share the same image layers efficiently.

Copy-on-write semantics minimize disk usage and startup time.

Effect:
OverlayFS enables immutability of images while allowing containers to have isolated, writable filesystems.


When running containers, you often need a way to store or share data outside the container’s writable layer. Docker provides two common mechanisms for this: bind mounts and volumes. While they look similar on the surface, they solve different problems.

A bind mount directly maps a file or directory from the host into the container. The path on the host must already exist, and the container sees the exact same data as the host. Any change made inside the container is immediately reflected on the host and vice versa. This makes bind mounts simple and fast, especially during local development, but they tightly couple the container to the host’s filesystem layout and permissions.

Because bind mounts expose host paths directly, they reduce portability and increase risk. Moving the container to another machine requires the same directory structure to exist. Misconfigured permissions or accidental writes can also affect the host system directly.

A Docker volume, in contrast, is a storage abstraction managed by Docker itself. Instead of pointing to a specific host path, you reference the volume by name. Docker decides where the data lives on the host and manages its lifecycle independently of containers. Volumes persist even when containers are deleted and can be reused across multiple containers.

Volumes are better suited for production workloads and stateful services. They offer safer defaults, clearer lifecycle management, and improved portability. Although volumes are backed by directories on the host, that detail is intentionally hidden so applications don’t depend on host-specific paths.

At the kernel level, both bind mounts and volumes are ultimately mounted into the container’s mount namespace. The real difference is not technical capability but who manages the storage. Bind mounts are host-managed and explicit; volumes are runtime-managed and abstracted.

In practice, bind mounts are ideal for development and quick iteration, while Docker volumes are the preferred choice for persistent data in production systems.


Layering in docker

Docker layering means an image is built as a stack of immutable, read-only filesystem layers, where each Dockerfile instruction creates a new layer representing the changes made at that step. These layers are cached and shared across images, which reduces disk usage and makes builds and pulls faster. When a container runs, Docker adds a thin writable layer on top of the image; all runtime file changes happen there and are discarded when the container is removed.

On Linux, Docker typically implements layering using OverlayFS (overlay2). OverlayFS combines multiple read-only image layers (lowerdir) with a single writable layer (upperdir) and presents them as one unified filesystem (merged) to the container. When a file is modified, OverlayFS uses copy-on-write: the file is first copied from a lower layer into the writable layer, then modified, keeping the original image layers unchanged.



--tty (-t): Allocates a pseudo-TTY, making the container behave like a real terminal.
--rm: Automatically removes the container when it stops.
-i: Keeps STDIN open so you can interact with the container.
-it: Combines interactive input (-i) with a terminal (-t) for an interactive shell.
docker start: Starts an existing stopped container.
docker attach: Attaches your terminal to a running container’s STDOUT/STDERR.



Docker filesystem layers:

Read-only layers: Immutable image layers that contain the application, runtime, and dependencies and are shared across containers.

Read/write layer: A single writable layer per container added on top of the image, where all runtime file changes are stored using copy-on-write.

Privileged mode (--privileged): Runs the container with almost full access to the host, disabling most isolation so it can access host devices, kernel features, and system capabilities (basically “container ≈ host”).

--pid=host: Shares the host’s PID namespace with the container, so the container can see and interact with all host processes

[Dockerfile
docker build
.dockerignore
](Dockerfile: A text file that defines how to build a Docker image using ordered instructions (FROM, RUN, COPY, etc.).

docker build: The command that reads the Dockerfile and builds an image from it.

.dockerignore: A file that lists files/directories to exclude from the build context to make builds faster and images smaller.)

A container does not need a distro. Docker containers share the host’s kernel, so the “OS” part (kernel, syscalls, process scheduling) already exists. A Linux distro mainly provides user-space tools (bash, coreutils, libc, package manager), not the kernel itself.

With FROM scratch, you’re just saying: “don’t give me any user-space files.”
If your app is a statically linked binary (for example, a Go binary), it already contains everything it needs in user space, so it can run directly using the host kernel. No shell, no libc, no /bin, no distro required.

That’s why scratch works — containers are process isolation, not virtual machines.

multibuild

Multi-stage (multibuild) Docker builds use multiple FROM instructions in one Dockerfile to separate build-time dependencies from the final runtime image. You compile or build your application in an earlier stage that has all required tools, then copy only the final output into a minimal image, which reduces image size, improves security, and keeps production images clean.

Example (Go app):

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


Example (Node.js):

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


Only the final stage is shipped, while earlier stages exist only during the build process.

Docker Compose: A tool to define and run multi-container apps on a single machine using a docker-compose.yml file (services, networks, volumes), great for local dev and simple deployments.

Docker Swarm: Docker’s built-in cluster/orchestration mode to run containers across multiple machines (nodes) with features like service replication, rolling updates, and built-in load balancing.



ENTRYPOINT and CMD are instructions that define what command runs when a container starts, but they differ in purpose and how they handle arguments. ENTRYPOINT sets the primary executable for the container, while CMD provides default arguments to that executable or defines a standalone command that can be easily overridden.
