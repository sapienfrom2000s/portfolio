---
title: "Terraform - Part 2"
date: 2026-03-06
categories: [Terraform]
tags: [Terraform]
---

### What are state files in Terraform?

- A state file stores the current state of infrastructure managed by Terraform
- It keeps track of resources Terraform has created and their attributes
- Terraform uses this file to understand what exists vs what needs to change

File name:

terraform.tfstate

Where it is stored:

- Local backend — stored on the local machine (default)
- Remote backend — stored in shared systems like S3, Terraform Cloud, etc.

Example:

- You run `terraform apply`
- Terraform creates resources (e.g., EC2, S3 bucket)
- Terraform records their IDs, metadata, and attributes in `terraform.tfstate`
- Later, `terraform plan` compares:
  - Terraform configuration
  - State file
  - Actual infrastructure

- Based on this comparison, Terraform decides what to create, update, or destroy


### What would happen if there was no state file?

- Terraform would not know what infrastructure it previously created
- It could try to recreate resources that already exist
- Updates and deletions would become unreliable
- Terraform would need to query the entire cloud infrastructure every time, which is inefficient and sometimes impossible

### How are `terraform plan`, `terraform apply`, and the state file related?

- The state file stores the current known state of infrastructure
- `terraform plan` compares three things:
  - Terraform configuration - checks `.tf` files
  - Terraform state file - checks the current state of resources
  - Actual infrastructure - queries the real infrastructure and matches it against the state file so that Terraform knows what resources exist and what needs to be changed

- Based on this comparison, Terraform determines what actions are required

Example flow:

1. `terraform plan`
   - Reads the configuration files
   - Reads the terraform.tfstate
   - Queries the real infrastructure
   - Shows what Terraform will create, update, or destroy

2. `terraform apply`
   - Executes the changes from the plan
   - Creates/updates/destroys infrastructure
   - Updates the state file with the new resource information

### What is the problem with storing the Terraform state file locally?

- The state file exists only on one machine
- Other team members cannot access the latest state
- This can cause conflicts if multiple people run Terraform

Example:

- User A runs `terraform apply`
- State file updates on User A's machine
- User B runs `terraform apply` from their machine
- User B's Terraform does not know about the latest changes
- This can lead to duplicate resources or infrastructure drift

Why not store the state file in GitHub?

- Terraform state files often contain sensitive data (resource IDs, ARNs, sometimes secrets)
- Git does not support locking, so multiple people could modify the state simultaneously
- Frequent state updates would create constant commits and merge conflicts
- A corrupted or incorrectly merged state file can break Terraform tracking

Solution:

- Use remote backends like S3 + DynamoDB, Terraform Cloud, etc.
- These provide shared storage and state locking

### What is a remote backend in Terraform?

- A remote backend stores the Terraform state file in a shared remote system instead of the local machine
- It allows multiple users to safely work on the same infrastructure

Why was it needed?

- Local state files make team collaboration difficult
- Multiple engineers running Terraform can cause conflicts or duplicate resources
- There is no locking with local state

Problem it solves:

- Provides centralized state storage
- Enables state locking to prevent simultaneous updates
- Makes infrastructure management safe for teams

Example (S3 backend):

terraform {
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}

- Terraform stores `terraform.tfstate` in S3
- DynamoDB provides locking
- If one user runs `terraform apply`, others must wait until the lock is released

### How do you configure a remote backend in Terraform?

- Remote backends are configured in the terraform block
- You specify the backend type and its configuration
- Terraform initializes the backend during `terraform init`

Example (S3 remote backend):

terraform {
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}

Configuration fields:

- bucket — S3 bucket where the state file will be stored  
- key — path to the state file inside the bucket  
- region — AWS region of the bucket  
- dynamodb_table — table used for state locking

Workflow:

- Write the backend configuration
- Run `terraform init`
- Terraform connects to the backend
- State is stored remotely instead of locally


### CI with Terraform

Terraform is commonly integrated with CI pipelines (GitHub Actions, GitLab CI, Jenkins, etc.) so infrastructure changes are automatically validated and applied when code is pushed. Typically, a pipeline runs `terraform init` and `terraform plan` on pull requests to preview infrastructure changes, and runs `terraform apply` after approval or merge to update the infrastructure. This ensures consistent deployments, automated validation, and controlled infrastructure changes through code reviews.

### What is state locking in Terraform?

- State locking prevents multiple users from modifying the Terraform state at the same time
- It ensures that only one Terraform operation (plan/apply) can run against the state at a time
- This avoids race conditions and infrastructure corruption
- When `terraform apply` starts, a lock entry is created in DynamoDB/Postgres/MySQL.
- When the operation finishes, the lock is released

Note - S3 is an object storage service that does not natively support state locking.

# Terraform Provisioners

## Motivation
Terraform creates infrastructure, but newly created servers are often not *usable* until they are configured (packages installed, configs copied, services started). Provisioners exist to bridge that gap when you need to perform one-off setup steps after resource creation.
Terraform offers provisioners for those tasks, but they should be used sparingly because they are less reliable (network timing, SSH failures), harder to make idempotent, and can hide configuration inside Terraform instead of a dedicated config tool.

## Alternatives to Provisioners
- `user_data` (cloud-init): Bootstrap on first boot for simple installs and config.
- Configuration management: Ansible, Chef, Puppet, or Salt for repeatable, idempotent system setup.
- Image baking: Build a preconfigured AMI with Packer so instances start ready.
- Managed services: Prefer PaaS offerings where possible to reduce host-level configuration.

## Core Concepts 

### 1) `file` provisioner
- Purpose: Copy files/directories from local machine to a remote instance.
- Use case: Push configs, scripts, assets to a server after it’s created.
- Requires: `connection` block (SSH / WinRM).

```hcl
resource "aws_instance" "demo_files" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"

  provisioner "file" {
    source      = "nginx.conf"
    destination = "/etc/nginx/nginx.conf"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
}
```

### 2) `remote-exec` provisioner
- Purpose: Run commands/scripts on the remote instance.
- Use case: Install packages, start services, apply on‑host setup.
- Requires: `connection` block (SSH / WinRM).

```hcl
resource "aws_instance" "demo_exec" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl enable --now httpd",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
}
```

### 3) `local-exec` provisioner
- Purpose: Run commands on the machine where Terraform runs.
- Use case: Notify, generate files, run local tooling based on outputs.
- Does NOT require a remote connection.

```hcl
resource "null_resource" "notify" {
  triggers = {
    instance_ip = aws_instance.demo.public_ip
  }

  provisioner "local-exec" {
    command = "echo Instance is up at ${self.triggers.instance_ip}"
  }
}
```

## Why Use Provisioners Instead of Ansible or `user_data`?
- Bootstrap gap: Sometimes you need a tiny, one‑time step (copy a file, run a quick command) and setting up Ansible is overkill.
- No OS boot hook available: If `user_data` is blocked, unavailable, or you’re not on a cloud that supports cloud‑init, provisioners can still run post‑create actions.
- Local side effects: `local-exec` can trigger local tooling (e.g., generate a file, send a notification) which Ansible or `user_data` won’t handle directly.
- Demos and learning: Provisioners are convenient for teaching or quick prototypes when you want everything in one Terraform plan.

Still, the recommended hierarchy is:
`user_data` for basic bootstrapping → Ansible for full configuration management → provisioners only as a last resort.
