---
title: "Learn jq: A Practical Guide"
date: 2026-03-17 10:00:00 +0530
categories: [Linux]
tags: [jq, json, cli]
---

# Learn `jq` by Example

If you work with JSON, `jq` is the fastest way to filter, transform, and query it from the command line. This guide is hands-on: it starts with a sample JSON file so you can copy it and run every command.

---

## Sample JSON (save as `sample.json`)

```json
{
  "company": "Acme Labs",
  "founded": 2012,
  "active": true,
  "tags": ["analytics", "cloud", "ai"],
  "employees": [
    {
      "id": 1,
      "name": "Ava Patel",
      "role": "Engineer",
      "skills": ["go", "kubernetes", "jq"],
      "salary": 125000,
      "manager_id": 3
    },
    {
      "id": 2,
      "name": "Liam Chen",
      "role": "Designer",
      "skills": ["figma", "ux"],
      "salary": 98000,
      "manager_id": 3
    },
    {
      "id": 3,
      "name": "Noah Singh",
      "role": "Manager",
      "skills": ["leadership", "planning"],
      "salary": 145000,
      "manager_id": null
    }
  ],
  "projects": [
    {"code": "NX-1", "name": "Neon", "budget": 250000, "status": "active"},
    {"code": "QL-9", "name": "Quill", "budget": 120000, "status": "paused"},
    {"code": "SP-2", "name": "Sparrow", "budget": 80000, "status": "active"}
  ],
  "offices": {
    "nyc": {"headcount": 35, "opened": 2016},
    "blr": {"headcount": 22, "opened": 2019}
  }
}
```

---

## 1) Pretty-print JSON

```bash
jq '.' sample.json
```

`jq` formats JSON nicely by default.

---

## 2) Access fields

```bash
jq '.company' sample.json
jq '.founded' sample.json
jq '.offices.nyc.headcount' sample.json
```

---

## 3) Array indexing

```bash
jq '.employees[0].name' sample.json
jq '.projects[2].code' sample.json
```

---

## 4) List all items in an array

```bash
jq '.employees[].name' sample.json
jq '.projects[].name' sample.json
```

---

## 5) Filter with `select`

```bash
jq '.projects[] | select(.status == "active")' sample.json
jq '.employees[] | select(.salary > 100000)' sample.json
```

---

## 6) Transform output

```bash
jq '.employees[] | {name, role}' sample.json
jq '.projects[] | {code, budget}' sample.json
```

---

## 7) Create new fields

```bash
jq '.employees[] | . + {level: (if .role == "Manager" then "senior" else "staff" end)}' sample.json
```

---

## 8) Work with arrays

```bash
jq '.tags | length' sample.json
jq '.tags | sort' sample.json
jq '.tags | join(", ")' sample.json
```

---

## 9) Aggregate values

```bash
jq '[.employees[].salary] | add' sample.json
jq '.projects | map(.budget) | add' sample.json
```

---

## 10) Group and count

```bash
jq '.employees | group_by(.role) | map({role: .[0].role, count: length})' sample.json
```

---

## 11) Work with objects

```bash
jq '.offices | keys' sample.json
jq '.offices | to_entries' sample.json
```

---

## 12) Output plain text

Use `-r` for raw strings.

```bash
jq -r '.employees[].name' sample.json
jq -r '.projects[] | "\(.code): \(.status)"' sample.json
```

---

## 13) Multiple fields per line

```bash
jq -r '.employees[] | "\(.name)\t\(.role)\t\(.salary)"' sample.json
```

---

## 14) Conditional filters

```bash
jq '.employees[] | select(.skills | index("jq"))' sample.json
```

---

## 15) Sort arrays

```bash
jq '.employees | sort_by(.salary)' sample.json
jq '.projects | sort_by(.budget) | reverse' sample.json
```

---

# Quick Reference

```bash
jq '.' sample.json                    # pretty print
jq '.field' sample.json               # access field
jq '.arr[]' sample.json               # iterate array
jq 'select(.x > 1)' sample.json       # filter
jq '{a, b}' sample.json               # create object
jq '.arr | length' sample.json        # array length
jq -r '.field' sample.json            # raw output
```

---

If you want, share your real JSON structure and I can craft exact `jq` filters for it.
