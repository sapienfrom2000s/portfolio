---
title: "Linux - Command Line Cheatsheet"
date: 2026-01-18 05:00:00 +0530
categories: [Linux]
tags: [linux, cheatsheet]
---

1. `tree`

To see the hierarchy of a directory.

2. `less`

To open a scrollable pager of a file.

3. `head`

To see the first n lines of a file.

4. `tail`

To see the last -n lines of a file. `tail -f file` is also very useful when
streaming is being done on that file.

5. Hard Link and Soft Link

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

6. `file`

Tells the content type that a file contains. Eg.:
```zsh
Downloads % file Wireshark\ 4.6.0.dmg
Wireshark 4.6.0.dmg: zlib compressed data
```

7. `stat`

Shows detailed metadata about file like: permissions, owner, size, timestamps.

8. `du` vs `df`

`du` - disk usage (works on directories)  
`df` - disk free (only for partition)

9. `sort`

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

--To be continued--
