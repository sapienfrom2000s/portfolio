---
title: "Learning Go: Day 1 - Table Generator"
date: 2025-10-20 12:00:00 +0000
categories: [Go, Learning]
tags: [golang, project, learning-journey, table-generator]
---

Starting a 30-day journey to build multiple programs in Go. This is Day 1.

## What is Table?

A simple Go program that generates multiplication tables. Given a number, it outputs the multiplication table for that number.

Example:
```
Enter the table number
5
5 x 1 = 5
5 x 2 = 10
5 x 3 = 15
...
```

## Repository

[sapienfrom2000s/table](https://github.com/sapienfrom2000s/table)

## Project Structure

```
table/
├── go.mod
├── go.sum
├── main.go
└── table/
    └── table.go
```

## Main Entry Point

The `main.go` file handles:
- Reading user input
- Calling the table generation function
- Printing the results

```go
package main

import (
	"fmt"
	"table"
)

func main() {
	var tableNumber int
	fmt.Println("Enter the table number")
	_, err := fmt.Scanln(&tableNumber)
	if err != nil {
		fmt.Printf("Error: %q occurred while reading user input", err)
	}

	t := table.GenerateTable(tableNumber)

	for _, v := range t.Table {
		fmt.Printf("%v x %v = %v", t.Number, v.Times, v.Value)
		fmt.Println()
	}
}
```

Tomorrow I'll try to create an uptime tracker for websites.
