---
title: "Scripts"
date: 2026-03-18 10:00:00 +0530
categories: [Scripts]
tags: [Python, Bash]
---

Q. Finding logs
-> Via grep and python
Searching for Internal Server Logs

python```
import re

pattern = r"\b5\d{2}\b"

with open('f.txt', 'r') as f:
    for line in f:
        if re.search(pattern, line):
            print(line.strip())

```

bash```
grep -E "\b5[0-9]{2}\b"
```
