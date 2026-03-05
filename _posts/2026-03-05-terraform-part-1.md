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

### Providers

A Terraform provider is a plugin that lets Terraform interact with an external platform (like AWS, Azure, GCP, Kubernetes) and create/manage 
resources there. Providers are of three types: Official providers maintained by HashiCorp (e.g., hashicorp/aws), Partner providers maintained by 
verified companies but published on the Terraform Registry (e.g., datadog/datadog, mongodb/mongodbatlas), and Community providers maintained by 
independent developers or the open-source community, which may have varying levels of maintenance and reliability.

### How is multi-region infrastructure configured?

- Terraform uses **multiple provider configurations** for different regions
- Each provider instance can have an **alias**
- Resources specify which provider (region) they should use

Example:

- Define providers for two regions

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

- Create resources in different regions

resource "aws_s3_bucket" "east_bucket" {
  bucket = "east-bucket-demo"
}

resource "aws_s3_bucket" "west_bucket" {
  provider = aws.west
  bucket   = "west-bucket-demo"
}

- Terraform creates one bucket in **us-east-1**
- Terraform creates another bucket in **us-west-2**

### How is hybrid cloud infrastructure configured?

- Terraform uses **multiple providers for different cloud platforms**
- Each provider manages resources in its respective cloud
- A single Terraform configuration can provision resources across clouds

Example:

- Define providers for AWS and GCP

provider "aws" {
  region = "us-east-1"
}

provider "google" {
  project = "my-project"
  region  = "us-central1"
}

- Create resources in both clouds

resource "aws_s3_bucket" "aws_bucket" {
  bucket = "aws-demo-bucket"
}

resource "google_storage_bucket" "gcp_bucket" {
  name     = "gcp-demo-bucket"
  location = "US"
}

- Terraform provisions resources in **AWS and GCP**
- This allows managing **hybrid cloud infrastructure from one configuration**

### What is an input variable?

- Input variables allow **passing values into Terraform configurations**
- They make configurations **reusable and flexible**
- Values can be provided via **CLI, tfvars files, or defaults**

Example:

- Define an input variable

variable "bucket_name" {
  type = string
}

- Use the variable in a resource

resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name
}

- When running Terraform, provide the value
- Terraform creates the bucket using the provided name

### What is an output variable?

- Output variables expose **useful information after Terraform applies**
- They help **share values between modules or show results**
- Commonly used for **resource IDs, URLs, or IP addresses**

Example:

- Define an output variable

output "bucket_name" {
  value = aws_s3_bucket.example.bucket
}

- After `terraform apply`, Terraform prints the output
- Other modules or systems can reference this value

### How is a Terraform directory structured?

- Terraform configurations are usually organized into **separate files by purpose**
- Terraform automatically loads all `.tf` files in the directory
- This helps keep infrastructure code **clean and maintainable**

Common structure:

- main.tf — primary resources and core infrastructure  
- providers.tf — provider definitions and configurations  
- variables.tf — input variable declarations  
- outputs.tf — output variables  
- terraform.tfvars — values for input variables

### What is `.tfvars` file?

- `.tfvars` files store **values for Terraform input variables**
- They separate **configuration (variables.tf)** from **environment-specific values**
- Terraform automatically loads `terraform.tfvars` if present

Example:

- Define a variable

variable "region" {
  type = string
}

- Provide value in `terraform.tfvars`

region = "us-east-1"

- Terraform reads the value from `.tfvars` during execution
- This avoids hardcoding values in configuration

Use cases:

- **Environment-specific configs** — different values for dev, staging, prod  
- **Team collaboration** — same Terraform code, different configs per team  
- **Secrets separation** — keep sensitive values outside main code  
- **Reusability** — reuse the same Terraform module across multiple setups

### What are built-in functions in Terraform?

- Terraform provides **built-in functions** to manipulate values, evaluate logic, and transform data inside configurations
- They help make configurations **dynamic and reusable**

Common examples:

- conditionals — choose values based on conditions  
  example: `var.env == "prod" ? 3 : 1`

- length() — returns the number of elements in a list or string  
  example: `length(var.subnets)`

- maps / lookup() — access values from key-value maps  
  example: `lookup(var.instance_types, "prod")`

- concat() — combine multiple lists  
  example: `concat(var.public_subnets, var.private_subnets)`

- format() — build formatted strings  
  example: `format("%s-%s", var.env, "bucket")`

These functions help **compute values instead of hardcoding them** in Terraform configurations.
