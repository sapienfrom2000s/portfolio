---
title: "Linux - Command Line Cheatsheet"
date: 2026-01-18 05:00:00 +0530
categories: [Linux]
tags: [linux, cheatsheet]
---

`tree`

To see the hierarchy of a directory.

`less`

To open a scrollable pager of a file.

`head`

To see the first n lines of a file.

`tail`

To see the last -n lines of a file. `tail -f file` is also very useful when
streaming is being done on that file.

`Hard Link and Soft Link`

What is inode?
-> Inode is a data structure which contains metadata about the file/directory. Whenever you try to
open a file, the location of the content is fetched from the metadata stored in inode.

Hard Link

Let's say you have a original file `f`. You can create a hard link to `f` by `ln f dup-hard`. The new file
points to the same node as the old one. Deleting one doesn't affect the other as the underlying `inode` is
not deleted as someone else is referencing it.

Soft Link

Soft link is a file which points to another file. It is created using `ln -s f dup-soft`. The new file
points to the original file. If original file is deleted, the sym link no longer works as the file that it
was pointing to doesn't exist anymore.

tldr;
hard link creates a new file which points to the original file's inode.
soft link creates a new inode to point to original file.

If underlying/original inode is deleted, the link(hard or soft) will not work. The inode is deleted only when the hard-link count becomes 0 (i.e., no hard links remain) and no process has it open.

Memory:
"Hard" = hard-attached to the data
"Soft" = like a shortcut

`file`

Tells the content type that a file contains. Eg.:
```zsh
Downloads % file Wireshark\ 4.6.0.dmg
Wireshark 4.6.0.dmg: zlib compressed data
```

`stat`

Shows detailed metadata about file like: permissions, owner, size, timestamps.

`du` vs `df`

`du` - disk usage (works on directories)  
`df` - disk free (only for partition)

`sort`

Examples:
```bash
# 1) Alphabetical sort (default)
sort names.txt

# 2) Numeric sort
sort -n numbers.txt

# 3) Human-readable size sort (largest first)
du -sh * | sort -hr

# 4) Unique sorted values (deduplicate)
sort -u words.txt

# 5) Sort by 2nd column, comma-separated (e.g., CSV)
sort -t ',' -k2,2 data.csv
```

Useful flags:
```txt
-n numeric sort (treat lines as numbers)
-h human-numeric sort (understands sizes like 10K, 2M, 1G)
-r reverse order
-u unique (remove duplicates after sorting)
-k sort by a specific key/column
-t set field delimiter (default: whitespace)
```

10. Permissions

For files:
`r` = read contents  
`w` = change contents  
`x` = run/execute

For directories:
`r` = list names (`ls`)  
`w` = create/delete/rename inside (needs `x` too)  
`x` = enter/traverse (`cd`), access files if you know the name

Numeric values:
`r` - 4  
`w` - 2  
`x` - 1

```bash
chmod +x something
chmod 755 something
chmod -x something
chmod g+rwx something
```

In normal Linux permissions, there are only these owners:

User owner (UID)  
Group owner (GID)

`chown`

Change owner both user and group:
```bash
chown user:group file
```

`chgrp`

Anything `chgrp` can do, `chown` can also do:
```bash
# both are equivalent
chgrp dev file
chown :dev file
```

`umask`

Manage the read/write/execute permissions that are masked out (i.e. restricted) for newly created files by the
user.

```bash
umask 022
# Directories: 777 - 022 = 755 -> rwxr-xr-x
# Files: 666 - 022 = 644 -> rw-r--r--

# Another way to look at it:
# umask is a “turn OFF these permission bits” mask (not real subtraction).
# Rule: final = base & ~umask

# Defaults:

# dirs base = 777 (rwxrwxrwx)
# files base = 666 (rw-rw-rw-)

# Example umask 022:

# 022 mask = --- -w- -w- (remove write for group + others)
# dirs: 777 & ~022 = 755 → rwxr-xr-x
# files: 666 & ~022 = 644 → rw-r--r--
```

`SUID` and `SGID`

- Normal user: can only change own password and must provide current password first.
- Root: can change anyone's password without knowing it and bypass restrictions.

How passwd actually works with SUID:

The /etc/shadow file structure:
```text
root:$6$encrypted_hash...:19000:0:99999:7:::
samantha:$6$encrypted_hash...:19000:0:99999:7:::
john:$6$encrypted_hash...:19000:0:99999:7:::
```
Each line = one user's password info; users should only modify their own line.

File permissions:
```text
-rw------- 1 root root /etc/shadow  (only root can read/write)
-rwsr-xr-x 1 root root /usr/bin/passwd  (SUID bit set)
```
What happens when Samantha (or any user) runs passwd:

- SUID makes the process run as root.
- Process effective UID = 0 (root).
- Process real UID = Samantha's UID (kernel tracks both).
- Process can now read/write /etc/shadow.
- Kernel allows it because effective UID = root.

Internal logic checks real UID:

- "Who started me?" -> Samantha.
- "Allow her to only modify the line: samantha:..."
- Prevents her from changing root's or john's password.

Program writes only Samantha's line:

- Reads entire file.
- Modifies only her line.
- Writes back to /etc/shadow.

Alternative 1: what if we give write permission to all users?

Attempt:
```text
-rw-rw-rw- 1 root root /etc/shadow  (world-writable)
-rwxr-xr-x 1 root root /usr/bin/passwd  (no SUID, just execute)
```
What happens:

- Process runs as Samantha.
- Internal logic: "She can change her password."
- Kernel allows write (file is world-writable).
- Program modifies only her line.

Also:

- Samantha can bypass passwd entirely.
- She can directly edit /etc/shadow with any text editor.
- She can change root's password, delete other users, etc.

Alternative 2: what if we only give execute permission?

Attempt:
```text
-rw------- 1 root root /etc/shadow  (only root can write)
-rwxr-xr-x 1 root root /usr/bin/passwd  (no SUID, just execute)
```
What happens:

- Samantha can execute passwd.
- Process runs as Samantha (process UID = Samantha).
- Kernel won't allow write because she lacks write permissions.

Execute permission != write permission:

- Process runs as Samantha.
- Samantha has no write access to /etc/shadow.
- Kernel blocks the write at system call level.
- Internal logic never gets to execute the write.

`Sticky bit`

Purpose:

- Directories (modern, most common): in a shared writable directory (like /tmp), it prevents users from deleting or renaming other users' files. Only the file owner, directory owner, or root can delete/rename entries.
- Executables (historical/mostly obsolete): on older Unix systems, it improved performance by keeping a program's code ("text segment") cached in swap/memory after it exited so it could start faster next time.

Why it's called "sticky":

- Historically, the executable's code would stick in swap/memory.
- Today, files in a shared directory stick to their owners (others can't remove them).

How it's represented:

ls -l:

- Shows t in the "others execute" position for directories (e.g., drwxrwxrwt).
- Shows T if sticky is set but others-execute isn't set(others can't go into the directory).
