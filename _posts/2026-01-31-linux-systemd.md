---
title: "Init System - Systemd"
date: 2026-01-31 05:00:00 +0530
categories: [Linux]
tags: [linux, systemd, init-system]
---

# Motivation

Systemd is the successor of SysV in many on of the Linux based OS'es. The advantages of systemd over SysV are:

1. Faster boot-up time since, daemons start paralelly as compared to sysV where everything was started sequentially.
2. Daemon scripts looked messy in sysV. Unit files are much easier to work with.
3. Every process runs in its own cgroup. Processes can be controlled more easily.

# Introduction

Systemd is an init system. It is the first process that is spinned up by kernel while booting. It is responsible to
spin up the other system and user services. These services are defined by both system and users. Some of them are
essential for making the system ready/usable by the user.

Every process in the OS is the descendent of PID 1.

# Linux Boot Process with Systemd

When a system is powered on, firmware(BIOS or UEFI) is executed.
The firmware performs POST(Power-On Self Test) to verify hardware.

In legacy BIOS systems, the BIOS loads the first 512 bytes of the boot device into memory, known as the Master Boot Record (MBR), which contains the bootloader.
In UEFI systems, the firmware directly loads the bootloader from the EFI System Partition(ESP).

The bootloader (e.g., GRUB, LILO) loads the Linux kernel into memory and passes control to it.
The kernel initializes hardware and mounts the root filesystem, then starts the first userspace process (PID 1), which on modern Linux systems is systemd.

systemd is then responsible for starting system services and bringing the system into a usable state.

systemd takes control as PID 1.
It determines the default boot target via default.target, which is usually a symlink to graphical.target or multi-user.target.

A target defines the desired system state by pulling in a set of units using dependency relationships such as Wants= and Requires=.
Units themselves may have further dependencies.

systemd analyzes all dependencies, builds a dependency graph, and starts units in the correct order while allowing parallel execution where possible.

# Unit Files

A unit is anything systemd can manage: a service, a mount, a timer, a socket, etc. Each unit is defined by a simple unit file:

```
[Section]
Directive=value
```

Most unit files follow the same pattern:

- **[Unit]**: metadata + relationships (what it is, what it depends on).
- **Type section** (like `[Service]`): the actual behavior.
- **[Install]**: only matters when enabling at boot.

Example:

```
[Unit]
Description=usbguard
[Service]
ExecStart=/usr/sbin/usb-daemon
[Install]
WantedBy=multi-user.target
```

# Common Unit Types

- **.service**: start/stop apps.
- **.timer**: cron-like scheduling that triggers a matching `.service`.
- **.target**: a system state (group of units).
- **.mount / .automount**: managed mounts.

There are more types, but these cover most daily admin work.

# Dependencies vs Order

Systemd has two separate ideas:

- **Dependencies**: "must run together?"
  - `Wants=`: try to start the other unit; continue even if it fails.
  - `Requires=`: must start successfully or this unit stops.

- **Order**: "who starts first?"
  - `After=` / `Before=`: only control sequencing, not success.

# Logging

`journalctl` reads systemd’s centralized logs. E.g. - `journalctl -u nginx`

# Targets

Targets represent "where" the system should land:

- **multi-user.target**: server/text login state.
- **graphical.target**: desktop state.
- **default.target**: the boot default (usually a symlink to one of the above).
- **rescue.target**: emergency shell.

# User Services

You can run services as a regular user:

- Unit files go in `$HOME/.config/systemd/user/`.
- Manage them with `systemctl --user`.
- User services stop on logout unless you enable lingering:
  `loginctl enable-linger USERNAME`

# systemctl

To interact with systemd units, we use `systemctl`:

- `systemctl status SERVICE`
- `systemctl start SERVICE`
- `systemctl stop SERVICE`
- `systemctl restart SERVICE`
- `systemctl enable SERVICE`
- `systemctl disable SERVICE`


Refs:

1. https://documentation.suse.com/smart/systems-management/pdf/systemd-basics_en.pdf
