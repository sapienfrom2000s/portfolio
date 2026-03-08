---
title: "Terraform - Cheat Sheet"
date: 2026-03-07 05:00:00 +0530
categories: [Terraform]
tags: [Terraform, cheatsheet, interview]
---

`terraform init`

Initialize working directory, download providers/modules, configure backend.

`terraform fmt`

Format configuration files to canonical style.

`terraform validate`

Validate syntax and internal consistency of configuration.

`terraform plan`

Create an execution plan showing proposed changes without applying.

`terraform plan -out=tfplan`

Save a plan to a file for later apply.

`terraform apply`

Apply the planned changes to reach desired state.

`terraform apply tfplan`

Apply a saved plan file to ensure exact changes.

`terraform destroy`

Destroy all infrastructure tracked in current state.

`terraform show`

Show state or a saved plan in a human-readable form.

`terraform output`

Read output values from the state.

`terraform console`

Open an interactive console for evaluating expressions.
Example:
```
> length(["a", "b", "c"])
3
```

`terraform providers`

Show required and configured providers.

`terraform graph`

Output dependency graph in DOT format.

`terraform workspace list`

List workspaces (logical state environments).

`terraform workspace new <name>`

Create a new workspace.

`terraform workspace select <name>`

Switch to another workspace.

`terraform state list`

List all resources tracked in state.

`terraform state show <addr>`

Show attributes for a specific resource in state.

`terraform state mv <src> <dst>`

Move/rename a resource in state without changing real infra.

`terraform state rm <addr>`

Remove a resource from state without destroying it.

`terraform import <addr> <id>`

Import an existing resource into state.

`terraform plan -refresh-only`

Only refresh state from real infrastructure, no changes.

`terraform apply -replace=<addr>`

Force recreation of a specific resource.

`terraform force-unlock <lock-id>`

Manually unlock state (use when lock is stuck).

`terraform -chdir=DIR <command>`

Run Terraform against configuration in another directory.

Common flags:

`-var="k=v"` set a variable from CLI.

`-var-file=FILE` load variables from a file.

`-auto-approve` skip interactive approval (use with care).

`-target=<addr>` apply or plan only specific resources (use sparingly).

`-parallelism=N` limit concurrent operations (rate limit sensitive APIs).

`TF_LOG=DEBUG` enable verbose logging for troubleshooting.
