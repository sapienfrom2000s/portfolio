---
title: "OverlayFS"
date: 2026-02-03 13:00:00 +0530
categories: [Linux, Filesystem]
tags: [linux, overlayfs, filesystem, docker]
---

# OverlayFS: concepts, conflicts, and whiteouts

OverlayFS is a union filesystem in the Linux kernel. It lets you stack a writable layer on top of one or more read-only layers and present a single merged view. This is the filesystem trick behind container images, immutable OS designs, and fast rollbacks.

This article explains how OverlayFS actually resolves files and directories, why whiteouts exist, and what to expect during common operations. It also includes practical, copy-pasteable examples.

---

## The mental model

Think in layers, not merges.

- **Lowerdir**: one or more read-only directories. You can stack multiple lowers.
- **Upperdir**: the writable layer. All changes go here.
- **Workdir**: scratch space used internally. Must be on the same filesystem as `upperdir` and empty when mounted.
- **Merged**: the mount point. This is what applications see.

OverlayFS uses strict priority, not content merging. The lookup order is:

```
upperdir
lowerdir (left to right)
```

If a path exists in upper, lower is ignored. If a path exists in multiple lowers, the leftmost wins.

---

## Quick lab setup

The following example builds a simple two-layer overlay. It is safe to run in a temp directory.

```bash
mkdir -p /tmp/ovl/{lower,upper,work,merged}

# Create two files in the lower layer
printf 'hello from lower
' > /tmp/ovl/lower/hello.txt
printf 'from lower only
' > /tmp/ovl/lower/only-lower.txt

# Mount the overlay
sudo mount -t overlay overlay -o lowerdir=/tmp/ovl/lower,upperdir=/tmp/ovl/upper,workdir=/tmp/ovl/work   /tmp/ovl/merged

# Inspect the merged view
ls -la /tmp/ovl/merged
```

You should see both files in `/tmp/ovl/merged`, but any change you make will land in `/tmp/ovl/upper`.

---

## File resolution rules (with examples)

### 1) File exists in upper and lower
Upper wins. Lower is ignored.

```bash
printf 'upper version
' > /tmp/ovl/upper/hello.txt
cat /tmp/ovl/merged/hello.txt
```

Output:

```
upper version
```

### 2) File exists only in lower
It is visible until you modify or hide it.

```bash
cat /tmp/ovl/merged/only-lower.txt
```

### 3) File exists in multiple lowers
Leftmost lower wins. For stacked lowers, the order in `lowerdir=` matters.

---

## Directory resolution rules (with examples)

Directories are merged by default, which means files from upper and lower appear together.

Example setup:

```
upper/etc/resolv.conf
lower/etc/hosts
```

Merged view:

```
/etc/hosts
/etc/resolv.conf
```

A directory is only replaced if it is explicitly marked opaque (covered below).

---

## Copy-on-write (copy-up)

When a file exists only in lower and you modify it, OverlayFS copies it up into upper and performs the write there.

```bash
# Change a lower-only file
printf 'changed in merged
' > /tmp/ovl/merged/only-lower.txt

# The file now exists in upper
ls -la /tmp/ovl/upper/only-lower.txt
```

Copy-up is triggered by:

- write
- chmod
- chown
- rename

---

## Whiteouts (deleting lower files)

Lower layers are read-only, so OverlayFS cannot delete lower files. Instead it hides them with a whiteout in upper.

```bash
# Delete a lower-only file
rm /tmp/ovl/merged/only-lower.txt

# OverlayFS creates a whiteout
ls -la /tmp/ovl/upper
```

You will see:

```
.wh.only-lower.txt
```

This means:

- the lower file still exists
- the merged view hides it
- the hide is implemented by the upper whiteout

If you recreate the file in merged, the whiteout is removed and the new file lives in upper.

---

## Opaque directories (directory deletion)

Whiteouts are for single entries. For directories, OverlayFS uses an opaque marker to stop merging lower contents.

```bash
rm -rf /tmp/ovl/merged/etc
```

OverlayFS behavior:

- creates `upper/etc/`
- sets xattr `trusted.overlay.opaque = "y"`

Effect:

- all lower `/etc/*` entries are hidden
- only upper `/etc` contents remain visible

---

## Rename handling (lower-only file)

Renaming a lower-only file triggers a copy-up and a whiteout.

```bash
mv /tmp/ovl/merged/hello.txt /tmp/ovl/merged/hello-renamed.txt
```

OverlayFS behavior:

- copies `hello.txt` to upper
- renames it in upper
- creates a whiteout for the old name

Result in upper:

```
hello-renamed.txt
.wh.hello.txt
```

---

## Metadata conflicts

Metadata changes behave like content changes: they trigger copy-up.

Rules:

- metadata changes trigger copy-up
- upper metadata always wins
- until copy-up, metadata comes from lower

Applies to:

- permissions
- ownership
- extended attributes

---

## What deleting a read-only file really means

You do not delete the file. You delete its visibility.

```bash
rm /tmp/ovl/merged/hello-renamed.txt
```

Actual result in upper:

```
.wh.hello-renamed.txt
```

Requirements:

- `upperdir` must be writable
- `lowerdir` is never modified
- lower file permissions do not matter

---

## What OverlayFS does NOT do

- no content merging
- no conflict detection
- no history tracking
- no concurrent write coordination

OverlayFS is deterministic and simple. If you keep the priority and whiteout rules in mind, its behavior is predictable.

---

## One-line truths

- OverlayFS hides, it does not delete
- Upper always beats lower
- Whiteouts are tombstones
- Opaque directories stop merging
- Copy-up preserves immutability



## What docker has to do with overlayfs?

Docker uses OverlayFS as a storage driver (commonly `overlay2`) to assemble image layers into a single writable filesystem for each container. Each image layer becomes a read-only lower directory, stacked in order, and the container gets its own writable upper directory. The merged view is what the container sees as its root filesystem.

When a container writes to a file that only exists in the image, OverlayFS performs copy-up into the container's upperdir, so the original layer stays untouched. When a container deletes a lower-layer file, OverlayFS creates a whiteout in the upperdir, hiding it without modifying the image. This is why deleting files in a container does not shrink the image and why container filesystems are fast to create and discard.

Key takeaways for Docker:

- Image layers map to lowerdirs; container changes map to upperdir.
- Copy-on-write keeps image layers immutable and shareable.
- Whiteouts and opaque directories represent deletions and directory "replacements" inside containers.
- Each container gets its own upperdir, so two containers from the same image do not see each other's changes.
