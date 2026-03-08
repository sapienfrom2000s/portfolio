---
title: "Github Actions"
date: 2026-03-07 05:00:00 +0530
categories: [Github Actions]
tags: [Github Actions]
---

# GitHub Actions

## Motivation

Before GitHub Actions, setting up automation meant:
- Signing up for a separate service (CircleCI, Jenkins, Travis CI)
- Connecting it to GitHub via webhooks
- Managing credentials across two platforms
- Debugging integrations whenever GitHub changed something

The core problem: **your code lived in one place, your automation lived somewhere else.**

GitHub Actions (launched 2019) solved this by putting CI/CD *inside* GitHub. Workflow files live in the same repo as your code, triggered by the same events, with direct repo access — no plumbing required.

---

## Comparison with Alternatives

| Tool | Native GitHub? | Self-hosted? | Best for |
|------|---------------|--------------|----------|
| **GitHub Actions** | ✅ Yes | Optional | GitHub repos, zero-friction setup |
| **Jenkins** | ❌ No | Required | On-prem, maximum control |
| **CircleCI** | ❌ No | Optional | Faster runners, speed-sensitive pipelines |
| **GitLab CI** | ❌ No (GitLab only) | Optional | GitLab repos |

---

## Key Vocabulary

| Term | What it means |
|------|--------------|
| **Workflow** | A YAML file in `.github/workflows/` — one automated process |
| **Event** | What triggers the workflow (push, PR, schedule, etc.) |
| **Job** | A chunk of work running on its own VM. Parallel by default |
| **Step** | A single command inside a job. Run sequentially |
| **Runner** | The VM that executes your job (`ubuntu-latest` is most common) |
| **Action** | A reusable plugin dropped in with `uses:` |
| **Secret** | An encrypted variable stored in GitHub Settings, never logged |

---

## Workflow File Structure

```yaml
name: My Pipeline          # Name shown in the GitHub UI

on:                        # TRIGGER — when does this run?
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:                      # JOBS — what does it do?
  my-job-id:               # Just a label you make up
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4   # Download your code
      - run: echo "Hello!"          # Run a shell command
```

---

## Common Triggers (`on:`)

```yaml
on:
  push:                        # On every push
  pull_request:                # On every PR
  schedule:
    - cron: '0 9 * * 1'       # Every Monday at 9am UTC
  workflow_dispatch:           # Manual trigger from GitHub UI
  release:
    types: [published]         # When you publish a release
```

---

## A Real CI Pipeline (Node.js)

```yaml
name: CI Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'         # Caches node_modules between runs

      - run: npm ci            # Clean install — safer than npm install in CI
      - run: npm run lint
      - run: npm test
```

---

## Job Dependencies (`needs:`)

Without `needs:`, all jobs run in parallel. Use `needs:` to chain them:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy:
    needs: test                            # Only runs if test passes
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'   # Only deploy from main
    steps:
      - run: ./deploy.sh
```

---

## Secrets

Never hardcode passwords. Store them in **GitHub → Settings → Secrets and variables → Actions**.

```yaml
steps:
  - name: Deploy
    run: ./deploy.sh
    env:
      API_KEY: ${{ secrets.API_KEY }}
      DB_URL: ${{ secrets.DATABASE_URL }}
      TOKEN: ${{ secrets.GITHUB_TOKEN }}   # Auto-provided by GitHub, no setup needed
```

---

## Matrix Builds

Test across multiple versions in one workflow:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]   # Runs the job 3 times
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm test
```

---

## Docker Build & Push

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Log in to GitHub Container Registry
    uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}   # No setup needed

  - name: Build and push
    uses: docker/build-push-action@v5
    with:
      context: .
      push: true
      tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
      cache-from: type=gha
      cache-to: type=gha,mode=max
```

---

## Useful Context Variables

| Variable | Value |
|----------|-------|
| `github.sha` | The commit SHA that triggered the run |
| `github.ref` | The branch/tag ref (e.g. `refs/heads/main`) |
| `github.actor` | The username who triggered the run |
| `github.repository` | `owner/repo-name` |
| `github.event_name` | The event type (`push`, `pull_request`, etc.) |

---

## Common Pitfalls

- **No `needs:`** → deploy job starts before tests finish
- **Hardcoded secrets** → always use `${{ secrets.NAME }}`
- **YAML indentation errors** → use a YAML linter or the GitHub browser editor
- **Tagging Docker images as `latest`** → always tag with `github.sha` for traceability
- **Secrets in forked PRs** → GitHub blocks secrets from fork PRs by design
- **Multiline run commands** → use the `|` operator:

```yaml
- run: |
    echo "line one"
    echo "line two"
```

---

## Quick Reference

```
.github/
  workflows/
    ci.yml          ← your workflow file

Trigger → Job(s) → Steps → Done
         (parallel)  (sequential)

needs:            → chain jobs in order
if:               → conditional execution
secrets:          → ${{ secrets.NAME }}
matrix:           → run job N times with different values
GITHUB_TOKEN      → auto-provided, no setup needed
```
