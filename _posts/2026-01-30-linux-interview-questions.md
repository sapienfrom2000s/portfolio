---
title: "Linux - Self Test"
date: 2026-01-30 05:00:00 +0530
categories: [Linux]
tags: [linux, test]
---

**Q:** What is bash? 
**A:** bash is a unix shell and scripting language generally used in linux based OS to interact with kernel.

**Q:** What is shell?
**A:** It is an optional user-level program that provides an interface to interact with the OS. A shell is not enforced by the operating system.

**Q:** What happens when user executes ls in bash shell?
**A:** User input → Bash parses command → fork() creates a new process → exec() loads ls → ls makes system calls
→ Kernel accesses filesystem & terminal → Output shown

**Q:** What is kernel? 
**A:** The kernel is the core component of an operating system that manages CPU scheduling, memory management, process management, context switching, and communication with hardware.

**Q:** What is linux?  
**A:** Linux is a free and open-source kernel that forms the core of many Unix-like operating systems, such as Ubuntu, Fedora, and Android.

**Q:** How to list files in sorted order of modified time?  
**A:** ls -ltr

**Q:** Why use bash over modern programming languages?
**A:** BTW, bash is a shell program. Shell programs provide interface to talk to kernel. Shell programs are readily available and can be executed
directly without importing libraries or compiling the code. It's good when you want to quickly mess around to get the system info and write some glue
code consisting of multiple shell programs(e.g.- cat bla | grep -v jkl | less)

**Q:** What is filesystem?
**A:** A filesystem defines how data is organized, stored, and retrieved on a storage device. Common filesystem formats include ext4, XFS, and Btrfs.

**Q** If I am seeing a process in htop. How do I know which executable executed it?
**A** There is a command column in htop. You can see the command that was executed to start the process. You can also use `sudo ls -l /proc/<PID>/exe`

**Q:** How to check the open ports in local machine?
**A:** netstat -tulpn

**Q:** What are /procs in linux?
**A:** /proc is a virtual filesystem (does not store data on disk; files are generated dynamically by the kernel and show live system and process data).
It is used to inspect running processes (/proc/<PID>/status, cmdline).
Helps monitor system resources like CPU and memory (/proc/cpuinfo, /proc/meminfo).
Used by commands like ps, top, and free

**Q:** What are cgroups?
**A:** Cgroups is a linux kernel feature which allows you to put constraints on resources(cpu, memory, I/O) that a process can use.

**Q:** What is I/O?
**A:** I/O (Input/Output) refers to how a program reads data from and writes data to external devices.
This includes disk, network, keyboard, display, etc. In cgroups, I/O control is used to limit disk bandwidth or IOPS so one process/container doesn’t starve others.

**Q:** Talk a bit about files in linux. "In Linux, everything is treated as a file", What is meant by this?
**A:**  When people said "everything is file", they mean that everything can be opened, read and written to as if it's a file, which is true to some extent, but in recent years is becoming less so. Eg.- open harddisk by cat /dev/sda, check process info in /proc/<PID>/status and so on.

**Q:** How to see processes with open ports?
**A:** ss -tulnp or netstat -tulnp

**Q:** How to see more info around a process? More info than what is shown in top and htop.
**A:** cat /proc/<PID>/status
       cat /proc/<PID>/cmdline
       ls -l /proc/<PID>/fd

tldr; look inside `/proc`

**Q:** What is a zombie process?
**A:** A zombie process is a process that has finished execution but still has an entry in the process table.
It occurs when the parent process hasn’t collected the child’s exit status using wait().
You can identify it in system tools as a Z (defunct) process.

**Q:** You have a webapp hosted on a ec2 instance. Suddenly the webapp got popular, given that you have no barriers
on finances, how will you design the system?
**A:** Compute: run on Kubernetes (EKS/GKE/AKS or self-managed) or Nomad. Keep workloads in containers + Helm/Kustomize → easy to move clouds.
Ingress/WAF/CDN: use Cloudflare (works with any origin) or Fastly; for WAF rules use OWASP CRS style policies you can reapply elsewhere.
Data: biggest lock-in is managed DBs. Pick Postgres (vanilla), keep SQL portable, avoid provider-specific extensions, use logical replication for migration.
Cache/Queues: use Redis (open source) and Kafka/RabbitMQ instead of SQS/managed streams if portability is priority.
Storage: S3 is de-facto, but use an S3-compatible API layer (MinIO, Ceph) and keep to standard ops; avoid vendor-only features (e.g., special eventing semantics).
Observability: OpenTelemetry + Prometheus/Grafana + Loki/ELK → no cloud-specific monitoring dependency.
Identity/Secrets: Vault (or at least a pluggable secrets interface) instead of tying app code to one secret manager.
IaC: Terraform/OpenTofu + GitOps so infra is reproducible across providers.

**Q:** How do you measure health around SQL based database? What type of observability you will put around it?
**A:** Health signals for an SQL database (what I’d measure)
Availability & connectivity: successful connection rate, auth failures, TLS errors, DNS issues.
Latency (by operation): p50/p95/p99 for SELECT/INSERT/UPDATE/DELETE, plus time-to-first-row for reads.
Throughput: TPS/QPS, rows read/written per sec, bytes in/out.
Saturation: CPU, RAM, disk IOPS/latency, disk queue depth, network, connection pool utilization.
Concurrency & contention: active connections, lock waits, deadlocks, blocked queries, hot rows/pages.
Query health: top N slow queries, plan changes/regressions, % queries using indexes, temp/sort spill to disk.
Replication & HA: replication lag, replica errors, failover events, WAL/binlog rate, sync status.
Storage & bloat: table/index size growth, free space, fragmentation/bloat, vacuum/analyze (for Postgres).
Error budget signals: query error rates, timeouts, aborted transactions, rollback rate.
Recovery posture: backup success + restore tests, PITR window, RPO/RTO confidence.
Observability stack around it (what I’d put in place)
Metrics (Prometheus/OpenTelemetry):
OS + disk (node exporter), DB exporter (e.g., postgres_exporter/mysqld_exporter)
Custom app metrics: per-endpoint DB time, pool wait time, retries, circuit-breaker opens.

Logs:
Structured DB logs: slow query log, lock wait log, deadlock log, checkpoint/vacuum logs.
App query logs with sampling (query fingerprint, duration, rows, error class) without PII.

Traces (OpenTelemetry):
Trace every request through app → DB, include spans for “pool wait”, “query”, “transaction”.
Tag with query fingerprint + table (not raw SQL) to keep it safe and aggregatable.
Continuous profiling (optional but powerful):
CPU profiling on app tier to spot ORM inefficiencies and N+1 patterns.

**Q:** What is lsof command?
**A:** lsof = List Open Files. On Unix/Linux, everything is a file (files, sockets, pipes, devices), so lsof shows which processes have which files or network connections open.
       `lsof -i :5432`

lsof -i :5432
-> shows which process is using port 5432 (for example, Postgres)

lsof -p 1234
-> lists all files and sockets opened by process with PID 1234

lsof /var/log/app.log
-> shows which process is reading or writing /var/log/app.log

lsof -u shivam
-> lists all files opened by user shivam

lsof -i TCP -sTCP:LISTEN
-> shows all processes listening on TCP ports

**Q:** Talk a bit about file permissions in linux.
**A:**

**Q:** Why snap apps are mounted as loop devices?
**A:** Snap apps are packaged as read-only squashfs image files and mounted using loop devices, which is why they appear as loopX and show 100% 
usage. This is an implementation detail, so Snap doesn’t usually mention it and hides it from normal users. Mounting apps this way enables 
strong isolation, atomic updates, and easy rollbacks.

**Q:** Explain mounting in linux?
**A:** Mount is the process of attaching a filesystem (usually on a device partition) to a directory in the system’s single filesystem tree.
It makes the device’s data accessible through that path without copying it.
A physical device may contain multiple filesystems via partitions, each mounted separately.
The system accesses storage via mount points, not directly via devices. FS examples are ext4, xfs, btrfs, zfs, etc.

**Q:** How to mount a filesystem?
**A:** To mount a filesystem, you need to specify the device or image file, the mount point, and the filesystem type. For example:
       `sudo mount /dev/sda1 /mnt` (system automatically detects the filesystem type)
       `sudo mount -t ext4 /dev/sda1 /mnt` (specify filesystem type explicitly, if expectation is not met, it will fail)

**Q:** Explain signals in linux.
**A:** Signals are lightweight, asynchronous notifications sent by the kernel or processes to a process (or thread) to indicate an event. Common signals include SIGINT (Ctrl+C), SIGTERM (polite termination), SIGKILL (force kill, cannot be caught), SIGSTOP (pause, cannot be caught), and SIGHUP (hangup/reload). Processes can handle most signals via signal handlers to clean up, reload config, or change behavior, but some (SIGKILL, SIGSTOP) are always enforced by the kernel. You can send signals with `kill -<SIGNAL> <pid>` or `killall`.

**Q:** Explain purpose of /etc/passwd file.
**A:**

**Q:** explain fstab.
**A:** The /etc/fstab (file systems table) is a crucial Linux configuration file that defines how disk partitions, remote file systems, and other data sources are automatically mounted at boot, ensuring persistent access

**Q:** Process vs Thread
**A:** A process is a container of memory and OS resources, while a thread is a unit of execution that exists inside a process and cannot live on its own. Every process has at least one thread, and multiple threads in the same process share the same address space and resources but each has its own stack and execution state. True parallel execution is limited by the number of CPU cores (sometimes doubled with hyper-threading), and when there are more threads than cores the OS schedules them over time, giving concurrency rather than real parallelism.

**Q:** What is a process?
**A:** A process is an instance of a running program. Chrome uses a separate process for each tab, which allows for better security (sandboxing tabs so a malicious page can’t access other tabs or system memory), crash isolation (if one tab crashes, the rest of the browser keeps running), and smoothness (slow or heavy tabs don’t freeze other tabs).

**Q:** What is RAID?
**A:** RAID is an orchestrated approach to computer data storage in which data is written to more than one secondary storage device for redundancy.

**Q:** As a DevOps Engineer, how would you manage resource allocation for different users and processes in a Linux system?
**A:** I would use Linux's built-in resource management tools to control and manage resource allocation.
For instance, using the ulimit command, I can set soft and hard limits on resources per user basis, limiting how much of a system's resources a user can consume.
For more granular control, I might use cgroups to set resource usage limits per process.

**Q:** How might you use the nice and renice commands in managing process priorities in Linux?
**A:** In Linux, the nice command is used to start a process with a specific priority, and renice is used to change the priority of an existing process. These tools help manage system performance by ensuring critical tasks receive the necessary CPU time over less critical ones.

**Q:** Talk a bit about sudo.
**A:** Early Unix had a very simple worldview. There were users, and there was root. Normal users could read their files and run programs; root could do 
  absolutely everything. If you needed to administer the system, you logged in as root or used su to become root. The model was clean, elegant, and brutally 
  literal. Unix didn’t try to understand intent or danger — it just enforced permissions. Every file, device, and kernel operation checked one thing: who are you, 
  and are you allowed to touch this?
  
  This worked fine when machines were small and admins were few, but reality crept in. Multi-user systems meant multiple admins, which meant a shared root password. 
  Root shells stayed open for hours, and people forgot who they were logged in as. Typos became disasters. When something broke, there was no trail — just a system 
  altered by “root,” with no way to know which human was behind it. Unix had assumed perfect operators; real operators were human.
  
  sudo emerged as a social fix to a technical system. Instead of becoming root permanently, an admin could ask for elevated power one command at a time. You stayed 
  yourself, proved your identity with your own password, and sudo briefly launched a process as root. That small pause — typing a password — forced intent. The 
  system gained logs, accountability, and restraint, without changing Unix’s core philosophy. The kernel still didn’t care about commands; it only cared that the 
  process now had UID 0.
  
  To keep this power from becoming chaotic again, sudo needed rules. That’s where sudoers came in — a policy file that defined who could run what, as whom, and 
  under what conditions. Not “what is dangerous,” but “who is allowed to cross the identity boundary.” A user might restart a service but not wipe disks; another 
  might manage containers but nothing else. Sudoers didn’t grant permissions itself — it simply controlled access to becoming someone who already had them.
  
  In the end, nothing magical was added to Unix. Permissions stayed the same. The kernel stayed strict and dumb. What changed was the recognition that power should 
  be temporary, explicit, and attributable. sudo is Unix admitting that the hardest part of system security isn’t files or processes — it’s people.

**Q:** Talk a bit about `2>&1`
**A:**

Basics of file descriptors:
- `0` is stdin
- `1` is stdout
- `2` is stderr

Redirect stdout to a file:

```sh
echo test > file.txt
# same as:
echo test 1> file.txt
```

Redirect stderr to a file:

```sh
echo test 2> file.txt
```

`>&` means “redirect this stream to another file descriptor”:

Redirect stdout to stderr:

```sh
echo test 1>&2
# same as:
echo test >&2
```

Redirect stderr to stdout:

```sh
echo test 2>&1
```

So in `2>&1`:
- `2>` means “redirect stderr”
- `&1` means “to wherever stdout is currently going”

Why `2>1` doesn't work:
`2>1` redirects stderr into a file literally named `1`. Without `&`, the shell treats `1` as a filename, not a file descriptor.
