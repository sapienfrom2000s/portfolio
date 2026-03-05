---
title: "Terraform - Part 1"
date: 2026-03-05
categories: [Terraform]
tags: [Terraform]
---

## Problem

How to create a AWS S3 bucket with some specific configuration?
There will be 3 main approaches to the problem:

1. Take help of UI. You click bunch of button in the AWS console and set it up.
2. Do it programmatically via AWS APIs.
3. Use cloudformation template. Pass it to AWS.

The first approach is easiest in short term but hardest to maintain in the long run.
The second approach is imperative. Need to write each and every step.
The third approach is declarative. Requires writing the least code. You just describe state
here.

Like AWS has CloudFormation, Azure has ARM (Azure Resource Manager) templates, and Google 
Cloud has Deployment Manager (or more modernly, Config Connector). But if your company uses multiple cloud providers, you'd have to learn and maintain 3 different templating systems — that's painful.
This is where Terraform comes in. Terraform is a cloud-agnostic IaC (Infrastructure as Code) tool — you write one consistent syntax (HCL — HashiCorp Configuration Language), and it works across AWS, Azure, GCP, and other providers. Alternatives - Crossplane, Pulumi

### What does `terraform init` do?

When you run `terraform init`, it performs three main tasks:

1. Downloads providers - A provider is a plugin that knows how to interact with a specific cloud platform such as AWS, Azure, or GCP. Terraform downloads the required provider plugins defined in your configuration into the `.terraform/` folder.

2. Initializes the backend connection — Terraform reads your backend configuration and verifies it can connect to wherever the state file will be stored (locally or remotely like S3). The state file itself is not created until terraform apply.

3. Downloads modules - If your configuration uses reusable modules (shared Terraform code), Terraform downloads those modules during initialization.

### What does `terraform plan` and `terraform apply` do?

`terraform plan` shows you what changes Terraform will make to your infrastructure based on your configuration. It doesn't actually make any changes — it just shows you what it would do.

`terraform apply` applies the changes shown in the plan. It makes the actual updates to your infrastructure.

### What is `.lock.hcl`?

.terraform.lock.hcl is a lock file that stores the exact provider versions Terraform should use.

- Locks provider versions (like aws 6.35.0)
- Stores checksums (hashes) to verify downloads
- Ensures consistent installs across machines

Example:

- You run terraform init
- Terraform records the provider version in .terraform.lock.hcl
- Teammates running terraform init get the same provider version

### What is `.terraform.tfstate`?

.terraform.tfstate is the state file that stores the current state of your infrastructure.

- Stores information about all resources Terraform manages
- Keeps resource IDs, attributes, and metadata
- Helps Terraform know what already exists

Example:

- You run terraform apply
- Terraform creates resources (like EC2, S3)
- Terraform records those resources in terraform.tfstate
- Later, terraform plan compares the configuration with this state

### What is `.lock.info` file?

- Stores information about the current state lock
- Prevents multiple users from modifying the state at the same time
- Helps avoid conflicts during terraform apply

Example:

- A user runs terraform apply
- Terraform locks the state
- .lock.info records details about the lock (who locked it, when)
- Other users cannot modify the state until the lock is released

Note:

- If .lock.info exists only on a local machine, teammates cannot see the lock
- This means multiple people could run terraform apply at the same time
- To avoid this, teams use remote backends with shared state locking (like S3 + DynamoDB, Terraform Cloud, etc.)

In short:
.lock.info = temporary file that tracks who is locking the Terraform state.
