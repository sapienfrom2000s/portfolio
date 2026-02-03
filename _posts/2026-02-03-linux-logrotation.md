---
title: "Logrotate Explained: Why It Exists and How It Works"
date: 2026-02-03 13:00:00 +0530
categories: [Linux]
tags: [linux, logrotate]
---

Logs are the backbone of debugging, monitoring, and auditing in any Linux-based system. But if left unmanaged, log files can grow indefinitely, consume disk space, and even bring production systems down.

This is where **logrotate** comes in.

In this post, we’ll cover:

- Why logrotate is needed
- How log rotation actually works
- A real-world logrotate configuration
- Important directives like `sharedscripts` and `postrotate`
- Common misconceptions and mistakes

## Why Do We Need Logrotate?

Applications continuously write logs:

```
app.log -> grows forever
```

Without log rotation:

- Disk fills up
- Applications crash or stop logging
- Servers become unstable

Logrotate automates log management by:

- Rotating old logs
- Compressing them
- Deleting logs beyond a retention limit
- Ensuring applications keep logging correctly

In short: logrotate prevents disk exhaustion and keeps logs manageable and reliable.

## How Logrotate Works (Conceptually)

Logrotate typically runs daily via `cron` or a systemd timer. It checks log files and:

1. Renames the current log
2. Creates a fresh log file
3. Optionally compresses older logs
4. Runs scripts to tell applications to reopen log files

## Does Logrotate Create a New Log File Every Day?

No. The application always writes to the same log filename, for example:

```
app.log
```

Logrotate only renames old logs.

### Example: `daily` + `rotate 7`

After multiple days, you’ll see:

```
app.log        # active log (always same name)
app.log.1
app.log.2
app.log.3.gz
app.log.4.gz
app.log.5.gz
app.log.6.gz
app.log.7.gz
```

- `app.log` -> current log
- `.1` -> most recent rotated log
- `.7` -> oldest kept log
- Oldest log is deleted when limit is exceeded

## Sample Logrotate Configuration (With Explanation)

```conf
/var/log/myapp/*.log {
    daily                 # Rotate logs every day
    rotate 7              # Keep last 7 rotated logs, delete older ones
    compress              # Compress rotated logs to save disk space
    delaycompress         # Delay compression by one rotation
                          # Useful if apps still access recent logs
    missingok             # Do not error if the log file does not exist
    notifempty            # Do not rotate empty log files
    create 0640 myapp myapp
                          # Create a new log file after rotation
                          # with given permissions and ownership
    sharedscripts         # Run postrotate script only once
                          # even if multiple logs are rotated
    postrotate
        systemctl reload myapp >/dev/null 2>&1 || true
                          # Reload the application so it reopens log files
                          # Avoid downtime; ignore errors safely
    endscript
}
```

## Enabling Logrotate for Your App (First-Time Setup)

Logrotate is triggered by a scheduler. On most systems this is either a systemd timer or a daily cron job. Make sure that scheduler is enabled, then add your app’s config.

1. Ensure logrotate is installed and the scheduler is enabled:

   - systemd-based distros:

     ```bash
     sudo systemctl enable --now logrotate.timer
     ```

2. Create a logrotate config file for your app in `/etc/logrotate.d/`:

   ```bash
   sudo nano /etc/logrotate.d/myapp
   ```

3. Paste the configuration block from the sample above and save.

4. Run a dry test to confirm logrotate parses the config correctly:

   ```bash
   sudo logrotate -d /etc/logrotate.conf
   ```

5. Force a one-time rotation to verify behavior (optional but useful):

   ```bash
   sudo logrotate -f /etc/logrotate.conf
   ```

6. Check your app logs and confirm:

   - A new active `app.log` exists
   - Rotated logs (`app.log.1`, `app.log.2.gz`, etc.) appear as expected
   - Your app continues logging after rotation


## Understanding `postrotate`, `endscript`, and `sharedscripts`

`postrotate`

- Defines commands to run after log rotation
- Commonly used to signal or reload applications

Example:

```conf
postrotate
  systemctl reload myapp
endscript
```

`endscript`

- Marks the end of a script block

`sharedscripts`

- By default, logrotate runs `postrotate` once per log file
- With `sharedscripts`, it runs only once, regardless of how many logs are rotated

Without `sharedscripts`, if files matched:

```
app1.log
app2.log
app3.log
```

Then:

```
systemctl reload myapp   # runs 3 times
```

This can cause:

- Unnecessary reloads

## Final Takeaways

- Logrotate prevents disk exhaustion and logging failures
- Applications always write to the same log filename
- Rotated logs are renamed as `.1`, `.2`, etc.
- `sharedscripts` is critical when reloading services
- `postrotate` defines what runs; `endscript` defines where it ends
