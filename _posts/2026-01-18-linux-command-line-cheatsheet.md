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

```
# first n lines
head -n 10 file.txt

# first c chars
head -c 10 file.txt

# offset
head -n 22 | tail -n 11
```

`tail`

To see the last -n lines of a file. `tail -f file` is also very useful when
streaming is being done on that file.

`Hard Link and Soft Link`

What is inode?

Inode is a data structure which contains metadata about the file/directory. Whenever you try to
open a file, the location of the content is fetched from the metadata stored in inode.

Hard Link

Let's say you have a original file `f`. You can create a hard link to `f` by `ln f dup-hard`. The new file
points to the same node as the old one. Deleting one doesn't affect the other as the underlying `inode` is
not deleted as someone else is referencing it.

Soft Link(aka. Sym Link)

Soft link is a file which points to another file. It is created using `ln -s f dup-soft`. The new file
points to the original file. If original file is deleted, the sym link no longer works as the file that it
was pointing to doesn't exist anymore.

tldr;

hard link creates a new file which points to the original file's inode.
soft link creates a new inode to point to original file.

**Memory**

1. Hard: name → inode → data
2. Soft: name → inode → path → inode → data

If underlying/original inode is deleted, the link(hard or soft) will not work. The inode is deleted only when the hard-link count becomes 0 (i.e., no hard links remain) and no process has it open.

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

`lsblk`

List block devices (disks, partitions, LVM, loop devices) in a tree.

Quick terminologies:
loop = Loop devices (or loopback devices) are a concept from Linux/Unix systems that let you treat a regular file as if it were a block device (like a hard disk or partition). Loop devices were needed because operating systems expect to mount filesystems from block devices (like /dev/sda1), but disk images are just regular files - so loop devices bridge this gap by presenting a regular file through the block device interface that the OS's mount system requires.

LVM (Logical Volume Manager) is a Linux layer that manages storage flexibly instead of fixed partitions.
It combines multiple disks into a single storage pool called a Volume Group.
From this pool, you create Logical Volumes like /home or /var.
Example: 100 GB + 200 GB disks become one 300 GB pool.
You can later add another disk and extend /home without downtime.

Examples:
```bash
# 1) Basic view (name, size, type, mountpoint)
lsblk

# 2) Show filesystem details
lsblk -f

# 3) Show sizes in bytes (no rounding)
lsblk -b

# 4) Custom columns
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
```

Useful flags:
```txt
-f show filesystem info (FSTYPE, UUID, LABEL, etc.)
-b sizes in bytes
-o pick columns to display
-p show full device paths (e.g., /dev/sda1)
```

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

`uniq`

Filter out repeated adjacent lines (usually after `sort`).

Examples:
```bash
# 1) Remove duplicates (needs sorted input)
sort names.txt | uniq

# 2) Count duplicates
sort names.txt | uniq -c

# 3) Print only lines that occur exactly once in a consecutive run
sort names.txt | uniq -u
```

Useful flags:
```txt
-c prefix lines by the number of occurrences
-d show only duplicate lines
```

`paste`

Merge lines from files side by side.

Examples:
```bash
# 1) Combine two files column-wise (tab-separated)
paste names.txt ages.txt

# 2) Use a custom delimiter
paste -d ',' names.txt ages.txt

# 3) Paste 3 columns side by side (tab-separated)
paste -d $'\t' - - -
```

Useful flags:
```txt
-d set delimiter (default: tab)
```

`cut`

Extract specific columns from each line of a file.

Examples:
```bash
# 1) Get 2nd column from a CSV
cut -d ',' -f2 data.csv

# 2) Get characters 1-10 from each line
cut -c 1-10 file.txt
```

Useful flags:
```txt
-d field delimiter (default: tab)
-f select fields (comma-separated or ranges)
-c select character positions (e.g., 1-5)
```

`tr`

Translate or delete characters (works on stdin).

Examples:
```bash
# 1) Lowercase to uppercase
echo "hello" | tr 'a-z' 'A-Z'

# 2) Remove digits
echo "a1b2c3" | tr -d '0-9'

# 3) Squeeze repeated spaces into one
echo "a   b     c" | tr -s ' '
```

Useful flags:
```txt
-d delete characters
-s squeeze repeats
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

`grep`

Common patterns:
```bash
# Basic match
grep "POST" app.log

# Case-insensitive match
grep -i "POST" app.log

# Invert match (lines that do NOT match)
grep -v "POST" app.log

# Context around matches
grep -C5 "POST" app.log    # before + after
grep -A5 "POST" app.log    # after
grep -B5 "POST" app.log    # before

# Recursive search
grep -r "POST" directory

# Line numbers + filenames
grep -n "POST" app.log
grep -l "POST" app.log     # list filenames with matches

# Match-only output + counting
grep -o "POST" app.log
grep -o "POST" app.log | wc -l

# Extended regex examples
grep -E '^ERROR' app.log
grep -E 'ERROR$' app.log
grep -E 'ERROR|WARNING' app.log
grep -E '^4..$' app.log
grep -E '^[234]00$' app.log
grep -E 'app/api/v2/.*ui/user' app.log

# Exit status (0 = found, 1 = not found)
grep -q 'POST' app.log; echo $?
```

`find`

Common patterns:
```bash
# Find by name (case-sensitive)
find . -name "app.log"

# Case-insensitive name
find . -iname "readme.md"

# Only files or only directories
find /var/log -type f
find /etc -type d

# Find by extension
find . -type f -name "*.log"

# Modified in last N days
find /var/log -type f -mtime -7

# Larger than 100MB
find /var -type f -size +100M

# Combine conditions (AND is default)
find . -type f -name "*.log" -mtime -3

# OR with parentheses (escape them)
find . \\( -name "*.log" -o -name "*.out" \\)

# Exclude a directory
find . -type f -name "*.log" -not -path "./node_modules/*"
```

Useful flags:
```txt
-name / -iname  match filename (case-sensitive / insensitive)
-type           f = file, d = directory, l = symlink
-mtime          modified time in days (-7 = last 7 days)
-size           file size (+100M, -10k, +1G)
-maxdepth       limit recursion depth
```

`sed`

Stream editor for fast, non-interactive text edits. 

- `sed` processes input line by line.
- You give it commands like substitute (`s///`), delete (`d`), print (`p`).
- By default, it prints every line after applying commands. Use `-n` to suppress auto-print and print only what you choose. Also, p can be used with g.

```bash
# Replace first match per line
sed 's/error/ERROR/' app.log

# Replace all matches per line (global)
sed 's/POST/HTTP_POST/g' app.log

# Use a different delimiter when slashes exist in the pattern
sed 's|/api/v1|/api/v2|g' access.log
```
- `s/old/new/` replaces the first `old` per line.
- Add `g` to replace all matches in the line.
- Any delimiter works (`s|a|b|` is often easier for paths).

Print only matching lines (like `grep`, but with transformations if needed):
```bash
sed -n '/ERROR/p' app.log
```
- `-n` turns off default printing.
- `/ERROR/` selects matching lines; `p` prints them.

Delete lines (filtering):
```bash
# Delete lines that match a pattern
sed '/DEBUG/d' app.log

# Delete a line range (inclusive)
sed '5,12d' app.log
```
- `/pattern/d` removes matching lines from output.
- `start,endd` drops a numeric line range.

Targeted edits by line range:
```bash
# Only change lines 10 to 20
sed '10,20s/timeout=30/timeout=60/' config.ini
```
- Line ranges let you be precise without touching the rest of the file.

```bash
# GNU sed (Linux): in-place edit(i flag), or it will print the changes to only stdout
sed -i 's/ENV=dev/ENV=prod/' .env
```

`awk`

Programming language for text processing. `awk` reads input line by line, splits each line into fields, and lets you write small programs to print, filter, and transform data.

Basics and fields (field separator, whole line, and column access):

```bash
awk -F ',' '{print $0}' file.csv
```
- `-F ','` sets the field separator to a comma (default is whitespace).
- `$0` means "the entire current line".

```bash
awk -F ',' '{print $1}' file.csv
```
- `$1` is the first field/column, `$2` is the second, etc.

```bash
awk -F ',' '{print $NF}' file.csv
```
- `NF` is the number of fields in the current line.
- `$NF` is the last field in the line, no matter how many columns there are.

```bash
awk -F ',' '{print NR ":", $0}' file.csv
```
- `NR` is the current record (line) number.
- Output looks like `1: <line contents>` for each each line

Substring by character position:
```bash
# From 2nd char, length 6
awk '{print substr($0,2,6)}' file

# From 2nd char to end of line (no length needed)
awk '{print substr($0,2)}' file
```
- `substr(s, start, len)` and `len` is optional; omit it to go to end of line.

Filters and matches (pattern matching and numeric comparisons):
```bash
awk '/ERROR/ {print}' app.log
```
- `/ERROR/` is a regex pattern.
- For any line that matches the pattern, the action `{print}` runs.
- `{print}` with no arguments prints the whole line (same as `print $0`).

```bash
awk '$4 > 200' app.log
awk '$2 == 234 && $3 == 233' app.log
awk '$9 ~ /^5/' access.log
```

Program structure (BEGIN / per-line / END):
```bash
awk 'BEGIN { } { } END { }' file
```
- `BEGIN { }` runs once before any input is read.
- `{ }` (the middle block) runs for each line.
- `END { }` runs once after all input is processed.
- This structure is great for setting counters, computing totals, and printing summaries.

Count values in a column (frequency table):
```bash
awk '{c[$2]++} END {for (i in c) print i, c[i]}' file
```
- `c[$2]++` increments a counter for the value in the second field.
- The `END` block prints each distinct value and its count.
- Output order is arbitrary because `awk` iterates associative arrays in hash order.

Sample output:
```text
200 10
400 5
500 3
```

`ufw`

Uncomplicated Firewall for quick host-level rules (common on Ubuntu/Debian).
Common patterns:
```bash
# Check status (use verbose for rules + defaults)
sudo ufw status
sudo ufw status verbose

# Enable / disable
sudo ufw enable
sudo ufw disable

# Allow a service or port
sudo ufw allow OpenSSH
sudo ufw allow 22
sudo ufw allow 80/tcp

# Deny a port
sudo ufw deny 23

# Allow from a specific IP
sudo ufw allow from 203.0.113.10

# Allow to a specific port from an IP
sudo ufw allow from 203.0.113.10 to any port 5432 proto tcp

# Delete a rule by number (from "ufw status numbered")
sudo ufw status numbered
sudo ufw delete 2
```

Useful flags:
```txt
status verbose   show defaults + active rules
status numbered  list rules with indexes for deletion
allow/deny       add rules (default is to apply immediately)
enable/disable   toggle firewall on or off
```

`systemd`

Default init system on most modern Linux distros.

```bash
# Service status and lifecycle
systemctl status nginx
systemctl start nginx
systemctl stop nginx
systemctl restart nginx
systemctl reload nginx

# Enable/disable on boot
systemctl enable nginx
systemctl disable nginx

# Show unit file + drop-ins
systemctl cat nginx
systemctl show nginx
```
- `status` is the first thing you check in production; it shows logs and the last exit code.
- `reload` sends a reload signal if the service supports it (no downtime).
- `enable` creates symlinks so the service starts at boot.

Logs with journald:
```bash
# Logs for a unit
journalctl -u nginx

# Follow logs like tail -f
journalctl -u nginx -f

# Logs since a time
journalctl -u nginx --since "1 hour ago"
```
- `journalctl` is centralized logs; you rarely grep files directly on systemd systems.

# Bash Scripting

Refs:
1. https://learnxinyminutes.com/bash/
2. Hackerranks bash challenge
