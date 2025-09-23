---
title: "sh vs Golang vs Ruby"
date: 2025-09-22 12:00:00 +0000
categories: [programming, ruby, sh, golang]
tags: [ruby, sh, golang]
---

## sh vs Golang vs Ruby

Ruby is the language that I started with. Even a 10 year old can pick it up. It's expressive,
powerful(DSLs) and sharp(cough cough metaprogramming). So many great tools like - chef, brew,
rails have been built around it. It has performance, availability and distribution issues though.
Since, ruby is an interpreted languague, runs on top of VM, it's slow. Talking about availability,
it doesn't come out of the box with anything apart from mac. You definitely need to install version
manager for development purposes. For the same performance reason you won't get it in machines where
you are ssh'ing into. By default ruby doesn't provide a tool that allows you to distribute programs
so that other machines can run it.

Golang is known for its simplicity, lightweight nature and strong concurrency support. It's a
compiled language that is faster than interpreted languages but slower than other compiled languages
such as Rust, C since the binary comes with a gc. Since it comes with gc, developer doesn't have
to manually clean up memory.

Enter sh: almost every machine comes with it out of the box. If you need to fetch system information
or automate something simple, sh or bash is often the first choice. You get access to powerful tools
like awk, sed, grep, find, etc., which make automating tasks easy. The availability is extremely
high! However, problems arise when you try to do something complex. Shell scripts are hard to read,
error handling is poor, concurrency support is minimal, and there is very limited support for data
structures.

Each of the above tools has its own strengths and weaknesses. It should be picked up based on the 
problem you are facing.
