# Repository Guidelines

## Project Structure & Module Organization
This repository is Terraform infrastructure for AWS, with Terraform Cloud as the remote workflow.
- Root files: `main.tf`, `variables.tf`, `outputs.tf`, `.terraform.lock.hcl`
- Reusable modules: `modules/network`, `modules/compute`, `modules/rds`, `modules/iam`, `modules/s3`, `modules/route53`
- Bootstrap/runtime templates: `templates/main`, `templates/monitoring`, `templates/loadtest`
- CI workflow: `.github/workflows/terraform.yml`

Keep cross-module wiring in root `main.tf`; keep resource implementation inside each module.

## Build, Test, and Development Commands
Use Terraform CLI from the repository root.
- `terraform init` initializes providers and modules.
- `terraform fmt -recursive` formats all `.tf` files.
- `terraform fmt -check -recursive` checks formatting (used in CI).
- `terraform validate -no-color` validates configuration.
- `terraform init -backend=false && terraform validate -no-color` runs local validation without touching remote backend.
- `terraform plan -var-file=dev.tfvars` previews infrastructure changes (if you use a `.tfvars` file locally).

## Coding Style & Naming Conventions
- Follow `terraform fmt` output; do not hand-align attributes.
- Use `snake_case` for variable and output identifiers (for example `db_instance_class`, `main_server_ip`).
- Keep module names and directory names lowercase (for example `modules/route53`).
- Prefer explicit descriptions for variables/outputs and consistent tags (`Name`, `Environment`, `Role`).

## Testing Guidelines
There is no separate unit-test framework in this repo. The quality gate is Terraform validation:
- Required before PR: `terraform fmt -check -recursive` and `terraform validate -no-color`
- Recommended before merge: `terraform plan` for the target environment and include a short plan summary in the PR.

## Commit & Pull Request Guidelines
Recent commits are short and task-focused (for example `log s3 추가`, `workflow제거`). Keep that brevity, but avoid placeholder messages like `tmp`.
- Suggested commit format: `<scope>: <change>` (for example `network: tighten SSH CIDR defaults`)
- PRs should include:
  - What changed and why
  - Related issue/ticket link (if available)
  - Terraform plan summary (or note that Terraform Cloud/VCS workflow will run plan/apply)
  - Any manual follow-up (DNS updates, secret rotation, etc.)

## Security & Configuration Tips
- Never commit secrets or local keys: `.tfvars`, `.pem`, `.key`, `.env` are ignored for this reason.
- Treat sensitive inputs (`db_username`, `db_password`) and the `ssh_private_key` output as secret material.
