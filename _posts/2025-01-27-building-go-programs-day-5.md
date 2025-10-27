---
title: "Learning Go: Day 1 - A Simple Go Quiz Game"
date: 2025-10-27 12:00:00 +0000
categories: [Go, Projects]
tags: [golang, project, game, quiz]
---

Built a simple command-line quiz game in Go that tests your knowledge of countries based on facts.

## What is Guess the Country?

A Go program that presents you with facts about a random country and gives you 5 attempts to guess the country name. It's a straightforward quiz game with a JSON data file containing country facts.

Example gameplay:
```
Fact 1: Known for its tech industry
Fact 2: Located in East Asia
Fact 3: Has a population over 120 million
Fact 4: Capital is Tokyo
Fact 5: Island nation

Try to guess the name of country based on the facts
You have 5 attempts
Japan
Yayy, you guessed it correctly
```

## Repository

[sapienfrom2000s/guess-the-country](https://github.com/sapienfrom2000s/guess-the-country)

## Project Structure

```
guess-the-country/
├── go.mod
├── main.go
└── data/
    └── countries_data.json
```

## How It Works

The program:
1. Loads country data from a JSON file
2. Shuffles the countries randomly
3. Selects 5 random countries and picks one as the target
4. Displays 5 facts about the target country
5. Gives you 5 attempts to guess the country name
6. Reveals the answer if you don't guess correctly

## Main Implementation

```go
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"os"
)

type countries_data struct {
	countries []country_data
}

type country_data struct {
	country string
	facts   []string
}

func main() {
	data, err := os.ReadFile("data/countries_data.json")
	if err != nil {
		log.Fatal("Error reading the file")
	}
	var dataSkeleton map[string][]string
	json.Unmarshal(data, &dataSkeleton)

	cdata := countries_data{}
	for key, value := range dataSkeleton {
		c := country_data{key, value}
		cdata.countries = append(cdata.countries, c)
	}
	cdata = shuffleData(cdata)
	sample := cdata.countries[0:5]
	countryName := sample[0].country
	facts := sample[0].facts
	for i := range len(sample[0].facts) {
		println(facts[i])
	}
	println("Try to guess the name of country based on the facts")
	println("You have 5 attempts")

	var attempedName string
	for _ = range 5 {
		fmt.Scanln(&attempedName)
		if attempedName == countryName {
			fmt.Println("Yayy, you guessed it correctly")
			return
		} else {
			fmt.Println("Try again, you can do it")
		}
	}
	fmt.Printf("The name of the country was %q\n", countryName)
}

func shuffleData(c countries_data) countries_data {
	rand.Shuffle(len(c.countries), func(i, j int) {
		c.countries[i], c.countries[j] = c.countries[j], c.countries[i]
	})
	return c
}
```

## Data Format

The `countries_data.json` file contains a simple key-value structure where each country maps to an array of facts:

```json
{
  "Japan": [
    "Known for its tech industry",
    "Located in East Asia",
    "Has a population over 120 million",
    "Capital is Tokyo",
    "Island nation"
  ],
  "Brazil": [
    "Largest country in South America",
    "Known for Amazon rainforest",
    "Host of 2016 Olympics",
    "Capital is Brasília",
    "Portuguese speaking"
  ]
}
```

## Key Takeaways

- Simple JSON unmarshaling in Go
- Using `rand.Shuffle` for randomization
- Basic file I/O with `os.ReadFile`
- Interactive command-line input with `fmt.Scanln`
- Straightforward game loop logic

This was a quick project to practice Go fundamentals. The game is fully functional and ready to play.

