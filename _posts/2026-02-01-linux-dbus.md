---
title: "An intro to D-Bus"
date: 2026-02-01 13:00:00 +0530
categories: [Linux]
tags: [linux, dbus, ipc]
---

# Motivation

On a local machine, applications often need to talk to each other to exchange information.
For example, if I am building a user application around battery health, I might need
information about the current battery percentage. To do this, my application should be
able to communicate with the system’s power management service and query it for this data.

Unix sockets, TCP, and UDP are some of the ways applications can communicate with each other,
assuming both sides conform to the same protocol. However, these mechanisms are relatively
low-level. For every protocol you want to support, you need to write extra boilerplate code.
Service discovery, security, lifecycle handling (service start/stop, crashes, restarts, and
availability checks) also become challenging.

This is where D-Bus helps.

# Intro

D-Bus is an IPC (Inter-Process Communication) system built on top of Unix domain sockets.
It hides many low-level details from applications, allowing them to focus primarily on
business logic rather than transport and coordination concerns.

D-Bus follows a client–service model:

- **Client**: An application (process) that connects to the D-Bus and makes method calls to
  request information or trigger actions.
- **Service**: An application (process) that owns a well-known name on the bus and exposes
  functionality.
- **Object**: A logical entity exposed by a service, identified by an object path, which
  implements one or more interfaces.

Services expose **objects** on the bus, and these objects implement **interfaces**.
An interface defines a set of **methods**, **signals**, and **properties** that can be used
by clients.

Clients can invoke methods on these objects to retrieve information or perform operations.
In addition to method calls, D-Bus supports a **signal mechanism**, where objects can emit
signals that are broadcast to all interested clients. This enables an event-driven or
publish–subscribe style of communication.

D-Bus itself is managed by a background daemon (`dbus-daemon`) that routes messages between
connected processes. The daemon also handles concerns such as service discovery, activation,
and basic access control. Commonly used buses include the **system bus** (for system-wide
services) and the **session bus** (for per-user services).

<img src="{{site.baseurl}}/assets/img/dbus-intro.png">

# References

1. https://wiki.freedesktop.org/www/IntroductionToDBus/
2. https://github.com/mvidner/ruby-dbus/blob/master/doc/Tutorial.md
