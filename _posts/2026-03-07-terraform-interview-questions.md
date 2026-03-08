# Terraform Mid-Level Interview Qs

---

## Q1. Walk me through the Terraform workflow

terraform init downloads and installs provider plugins into `.terraform/`, stores their hashes in `.terraform.lock.hcl` for reproducibility, downloads any modules referenced in the config, and sets up the backend (e.g. S3) where state will be stored.

terraform plan fetches the latest state from the remote backend, calls provider APIs to refresh actual resource attributes, compares current state vs desired config, and outputs a diff showing what will be created, changed, or destroyed.

terraform apply acquires a state lock (via DynamoDB if using S3 backend), calls provider APIs to make the actual changes, writes the new state to the backend, then releases the lock.

Note: drift is detected during plan. Apply reconciles drift — it doesn't fail because of it. It fails if the API call itself errors due to permissions, conflicts, etc.

---

## Q2. "Error acquiring the state lock" — causes and resolution

There are two common causes. First, a teammate is actively running terraform apply. Second, a previous apply exited ungracefully (crash, Ctrl+C, killed pipeline) and didn't release the lock.

To investigate, check the lock metadata in DynamoDB or S3 to see when the lock was acquired. If it's recent, coordinate with your team. If it's clearly abandoned, force-unlock it.

```bash
terraform force-unlock <LOCK_ID>
```

The Lock ID appears in the error message itself.

The key risk: force-unlocking while someone is actively applying can cause state corruption — two processes writing state simultaneously. Always verify the lock is truly stale before running this.

---

## Q3. What is a Terraform module and what makes a good one?

A module is a reusable, self-contained unit of Terraform config. The main use case is DRYing out infrastructure — for example, dev and prod share the same base infra, so you extract the common parts into a module and call it with different variables.

The root module is the directory where you run terraform apply — your entry point. A child module is any module called by the root via a `module {}` block.

```hcl
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
}
```

A well-designed module is abstract, self-contained, focused on one thing, configurable via variables with sensible defaults, exposes outputs for other modules to consume, and is version-pinned when sourced from a registry.

---

## Q4. Workspaces and remote state sharing

Workspaces let you maintain multiple state files from the same configuration — like git branches for state.

```bash
terraform workspace new dev
terraform workspace select prod
terraform apply
```

In practice most teams avoid workspaces for environment separation because all workspaces share the same codebase and backend config, it's easy to apply to the wrong workspace, and it doesn't scale well. Separate directories per environment is more common.

To share state between configurations, use terraform_remote_state:

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "app" {
  subnet_id = data.terraform_remote_state.vpc.outputs.subnet_id
}
```

The VPC config must declare the output for this to work.

---

## Q5. The lifecycle block

The lifecycle block controls how Terraform manages changes to a resource, overriding default behaviour.

create_before_destroy — by default Terraform destroys then creates when a resource must be replaced, causing downtime. This flips the order. Use it for EC2 instances behind a load balancer.

prevent_destroy — Terraform throws an error if anything tries to destroy this resource, even terraform destroy. Use it on production databases as a safeguard against accidental deletion.

ignore_changes — tells Terraform to ignore drift on specific attributes. Use it for an Auto Scaling Group where instance count is managed by AWS autoscaling policies, not Terraform. Without this, every plan would try to reset the count.

```hcl
lifecycle {
  create_before_destroy = true
  prevent_destroy       = true
  ignore_changes        = [desired_capacity]
}
```

---

## Q6. You run terraform plan and see 50+ resources being destroyed unexpectedly

# Why Does Terraform Want to Destroy 50+ Resources?

The common thread across all causes is the same: Terraform only knows what's in its state file. Anything that breaks the link between state and reality makes Terraform think resources disappeared, and it tries to recreate them.

---

## Cause 1: Someone renamed a resource without terraform state mv

Imagine you have this in your code:

```hcl
resource "aws_instance" "web_server" { ... }
```

A teammate refactors and renames it to:

```hcl
resource "aws_instance" "app_server" { ... }
```

To Terraform, `aws_instance.web_server` and `aws_instance.app_server` are completely different things. It doesn't know you just renamed it. So it looks at state, sees `web_server` exists but is no longer in code — destroy it. Then sees `app_server` in code but not in state — create it. One rename = one destroy + one create. Now imagine this happened across 50 resources during a big refactor.

The fix is to run this before applying:

```bash
terraform state mv aws_instance.web_server aws_instance.app_server
```

This renames it in state so Terraform understands it's the same resource.

---

## Cause 2: Provider version upgrade

Providers occasionally change how they identify resources internally between versions. For example, an older AWS provider might track a security group by one internal ID format, and a newer version tracks it differently. When you upgrade the provider, Terraform looks at state and thinks all those resources are gone, so it wants to recreate them all.

This is rarer but it does happen, and it's why you pin provider versions and upgrade carefully.

```hcl
terraform {
  required_providers {
    aws = { version = "~> 5.0" }  # pinned, won't auto-upgrade
  }
}
```

## Cause 4: Backend switched without migrating state

Say your team was storing state locally in `terraform.tfstate`. Someone sets up an S3 backend but doesn't migrate the existing state — just points to an empty S3 bucket. Now Terraform sees an empty state and thinks nothing exists yet, so it wants to create everything from scratch. But the real infrastructure already exists — it just doesn't know about it.

The fix is to run this when switching backends, which copies existing state to the new backend before doing anything:

```bash
terraform init -migrate-state
```

---

## Q7. Security best practices in Terraform

Never hardcode credentials in config files. Use AWS Secrets Manager or similar to inject secrets at runtime.

Don't store state in version control. State files contain plaintext secrets like database passwords. Use a remote backend with encryption at rest enabled, and enable versioning on the S3 bucket so you can roll back a corrupted state.

Give least privilege to the machine user running terraform. Prefer IAM roles over IAM users with long-lived access keys. In CI/CD, use OIDC federation so GitHub Actions assumes a role dynamically — no stored secrets at all.

Pin provider versions to avoid unexpected behaviour on init:

```hcl
terraform {
  required_providers {
    aws = { version = "~> 5.0" }
  }
}
```

Run tfsec or checkov in CI to catch misconfigurations early.

---

## Q8. count vs for_each

count creates N copies of a resource tracked by index. The problem is if you remove an item from the middle of a list, everything shifts — 
Terraform sees this as changes to every resource after that index, causing unnecessary destroys and recreates.

for_each solves this by tracking resources by key, not index. Removing one item only affects that item — everything else is untouched.

```hcl
# count — fragile, tracks by index
resource "aws_iam_user" "users" {
  count = length(var.users)
  name  = var.users[count.index]
}

# for_each — robust, tracks by key
resource "aws_iam_user" "users" {
  for_each = toset(["alice", "bob", "charlie"])
  name     = each.key
}
```

Use count only for simple enable/disable patterns like `count = var.create_resource ? 1 : 0`. For anything involving a list of named resources, 
always use for_each.


# How to Import Existing Infrastructure into Terraform

When a company already has infrastructure running and wants to bring it under Terraform, the core tool is `terraform import`. The idea is simple — Terraform doesn't know about infrastructure it didn't create, so you manually tell it "this real resource corresponds to this config block." Once imported, Terraform tracks it in state like any other resource.

---

## The Three Approaches

### 1. terraform import (built-in, one resource at a time)

Write the resource block first — Terraform requires config to exist before importing:

```hcl
resource "aws_instance" "app" {
  ami           = "ami-12345"
  instance_type = "t3.micro"
}
```

Then import using the real cloud resource ID:

```bash
terraform import aws_instance.app i-1234567890abcdef0
```

Run `terraform plan` after every import. You'll almost always see a diff because the real resource has attributes you haven't written yet. Keep updating config until the plan shows no changes. That's your goal — a completely clean plan.

Best for: small number of resources, or when you already have config written.

Cons: imports one resource at a time — slow for large infra. Doesn't generate config, you write everything by hand. Easy to miss attributes, leaving a dirty plan that modifies resources on next apply.

---

### 2. Native import block with config generation (Terraform 1.5+)

Define the import in code instead of running CLI commands one by one:

```hcl
import {
  to = aws_instance.app
  id = "i-1234567890abcdef0"
}
```

Then let Terraform generate the config for you:

```bash
terraform plan -generate-config-out=generated.tf
```

This writes a full `.tf` file based on the real resource attributes. You review, clean up, and commit it. Best of both worlds — built-in, no third-party tool, and handles config generation automatically.

Best for: medium migrations where you want automation without a third-party dependency.

Cons: only available from Terraform 1.5+ — older codebases can't use it. Generated config is verbose and needs cleanup before it's production-ready. Still requires you to know the resource ID upfront for each resource.

---

### 3. terraformer (third-party, bulk generation)

Scans your cloud account and generates both state and config automatically for all resources at once:

```bash
terraformer import aws \
  --resources=vpc,subnet,igw,route_table,security_group,nat \
  --regions=us-east-1 \
  --filter=vpc=vpc-0a1b2c3d4e5f
```

The `--filter` flag scopes it to a specific VPC so you don't pull in the entire account. Fast for large migrations, but the generated code is often messy — inconsistent naming, redundant attributes, no module structure. Treat the output as a starting point, not production-ready code.

Best for: large existing infrastructure where writing config by hand would take days.

Cons: third-party tool — not maintained by HashiCorp, can lag behind new provider versions. Generated code is messy with poor naming and no module structure. Can pull in more than you expect if filters aren't set carefully. Generated state sometimes has drift issues that need manual fixing.

---

## Migrating a Full VPC

A VPC is not one resource — it's a collection of interconnected ones. You need to import all of them. The full list: VPC, subnets, internet gateway, route tables, route table associations, security groups, NAT gateway, elastic IPs, network ACLs.

Write config for each resource first:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "app" {
  vpc_id = aws_vpc.main.id
}
```

Then import each resource using its AWS ID (get these from the console or CLI):

```bash
terraform import aws_vpc.main vpc-0a1b2c3d4e5f
terraform import aws_subnet.public_1 subnet-0a1b2c3d
terraform import aws_internet_gateway.main igw-0a1b2c3d
terraform import aws_route_table.public rtb-0a1b2c3d
terraform import aws_route_table_association.public_1 subnet-0a1b2c3d/rtb-0a1b2c3d
terraform import aws_security_group.app sg-0a1b2c3d
```

For a large VPC, use terraformer with the `--filter` flag instead of importing manually.


Q. How do you detect drift on a continuous basis? If someone has changed the infra via UI, how would you know without running command?
A. 

Q: How do you maintain resource creation order in Terraform?
A: Terraform maintains order using a dependency graph, where resources are created based on implicit references or explicit depends_on dependencies.


# Terraform Mid-Level Interview — Q&A (Q11 onwards)

---

## Q11. How do you run scripts on an EC2 instance after creation in Terraform?

Use the **remote-exec provisioner**. It SSHs into the instance and runs commands.

```hcl
connection {
  type        = "ssh"
  host        = self.public_ip
  user        = "ec2-user"
  private_key = file("~/.ssh/my-key.pem")
}

provisioner "remote-exec" {
  inline = ["sudo yum install -y nginx"]
}
```

Three provisioner types: `local-exec`, `remote-exec`, `file`.

**Prefer user_data or Ansible** — provisioners aren't tracked in state, so failures can go undetected.

---

## Q12. How do you roll back a bad Terraform apply?

**Option 1 — Git rollback (preferred):** Revert the commit, merge, let the pipeline re-apply. Keeps audit trail intact.

**Option 2 — State rollback:** Pull previous state version from S3, push it back, then run apply to reconcile.

```bash
terraform state push previous.tfstate
terraform apply
```

**Tip:** Restore service at the app layer first, then fix Terraform after.

---

## Q13. What is the difference between a `resource` and a `data` source?

- `resource` — Terraform **creates and manages** it
- `data` — Terraform **reads existing info**, never modifies it

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app" {
  ami = data.aws_ami.amazon_linux.id
}
```

Common uses: look up existing VPCs, fetch secrets, read Route53 zones.

---

## Q14. What is `terraform taint` and when would you use it?

Marks a resource as degraded so Terraform **destroys and recreates it on next apply**.

Use when an instance is running but in a broken state — e.g. bootstrap script failed halfway.

```bash
# Deprecated (pre 1.2)
terraform taint aws_instance.app

# Modern equivalent
terraform apply -replace=aws_instance.app
```

**Note:** `terraform taint` is deprecated from Terraform 1.2+. Use `-replace` instead.

---

## Q15. What safeguards would you add to auto-apply Terraform in CI/CD?

- **Plan before apply** — always save and apply the plan file
```bash
terraform plan -out=tfplan
terraform apply tfplan
```
- **Manual approval gate** for production
- **State locking** — DynamoDB with S3 backend to prevent concurrent applies
- **Least privilege IAM role** for the CI runner
- **Atlantis** — runs plan on PR, posts diff as comment, requires approval before apply
- Block all manual infra changes via AWS SCPs

---

## Q16. What does `terraform refresh` do and why be careful?

Queries real cloud APIs and updates state to match current reality.

**Risk:** Silently overwrites state with whatever exists in the cloud — including accidental deletions. If someone deleted a subnet in the console, refresh removes it from state too.

**Note:** `terraform refresh` is deprecated from Terraform 1.2+. Use instead:

```bash
terraform apply -refresh-only
```

This shows a plan first so you can review before committing changes to state.

---

## Q17. What is a Terraform backend and what should you consider when choosing one?

A backend stores remote state. Key considerations:

- **State locking** — S3 alone has no locking, pair it with DynamoDB
- **Encryption at rest** — always enable SSE on S3
- **Versioning** — enable on the S3 bucket for rollback capability
- **Access control** — restrict bucket policy to CI role only

```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

For larger teams, **Terraform Cloud** adds UI, run history, and approval workflows.

---

## Q18. How do you provision infrastructure across 3 AWS accounts (dev/staging/prod)?

**Code structure** — shared modules, separate state per environment:

```
environments/
  dev/
  staging/
  prod/
modules/
  vpc/
  ec2/
```

**Multi-account auth** — use provider aliases with IAM role assumption. No stored credentials.

```hcl
provider "aws" {
  alias = "dev"
  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/TerraformRole"
  }
}

provider "aws" {
  alias = "prod"
  assume_role {
    role_arn = "arn:aws:iam::999999999999:role/TerraformRole"
  }
}
```

CI runner has one IAM role and **assumes a role** in each target account via OIDC federation — no long-lived credentials stored anywhere.


Q. Junior devops engineer accidentally deleted state file. How would you recover it? How would you prevent it from happening again?
A.
https://cloudchamp.notion.site/Terraform-Scenario-based-Interview-Questions-bce29cb359b243b4a1ab3191418bfaab
