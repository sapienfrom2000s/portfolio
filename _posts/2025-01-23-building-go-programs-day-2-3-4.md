---
title: "Learning Go: Days 2-4 - Uptime Tracker"
date: 2025-10-23 12:00:00 +0000
categories: [Go, Learning]
tags: [golang, project, learning-journey, uptime-tracker, sqlite, cron]
---

Continuing the 30-day journey. Days 2-4 focused on building an uptime tracker for websites.

## What is Uptime Tracker?

A Go application that monitors website availability. It periodically checks if websites are up or down and stores the results in a database. The datapoints are then shown on the UI. The system has three main components:

1. **Cronjob** - Periodically checks website status
2. **Web Server** - Serves the status data via API
3. **Frontend** - Displays the status data

## How It Works

### Cronjob Component

Runs on a schedule and:
- Fetches all tracked URLs from the database
- Makes HTTP requests to each URL every second
- Records whether each request succeeded (HTTP 200) or failed
- Stores results in the database

### Web Server Component

Provides an API endpoint:
- `GET /v1/trackers/status` - Returns the last 60 status checks

## Repository

[sapienfrom2000s/uptime-tracker](https://github.com/sapienfrom2000s/uptime-tracker)

## Project Structure

```
uptime-tracker/
├── backend/
│   ├── cronjob/
│   │   ├── go.mod
│   │   └── main.go
│   ├── webserver/
│   │   ├── go.mod
│   │   └── main.go
│   └── db/
│       └── sqlite.db
└── frontend/
```

## Database Schema

Two tables:

**Trackers** - Stores URLs to monitor
```
ID (INTEGER)
url (TEXT)
```

**UptimeStatuses** - Stores status check results
```
ID (INTEGER)
tracker_id (INTEGER)
up (BOOLEAN)
```

## Key Technologies

- **SQLite** - Lightweight database for storing trackers and status history
- **Gin** - Web framework for the API server
- **Robfig/Cron** - Scheduling library for periodic checks

## Cronjob Flow

```go
1. Connect to SQLite database
2. Query all tracked URLs
3. For each URL:
   - Create a cron job that runs every 1 second
   - Make HTTP GET request
   - Check if response status is 200 (OK)
   - Insert result into UptimeStatuses table
4. Run for 15 minutes (900 seconds)
5. Stop and exit
```

## Web Server Flow

```go
1. Connect to SQLite database
2. Create Trackers table if it doesn't exist
3. Create UptimeStatuses table if it doesn't exist
4. Start Gin server with CORS enabled
5. Serve /v1/trackers/status endpoint
6. Return last 60 status checks as JSON array
```

