# Terraform Learning Projects (AWS)

A curated collection of Terraform projects for learning and reusing common AWS infrastructure patterns. Each folder is a self‑contained example that you can run independently. Scenarios range from fundamentals (variables, outputs) to real architectures (two‑tier apps, ECS, CloudFront + Lambda@Edge, S3 static hosting, Route53, and more).

> Tip: Most projects include their own README with specifics. Start here to understand the repo layout and how to run any project consistently.

## Table of contents

- Overview
- Prerequisites
- How to run any project (PowerShell)
- Project catalog
- Costs and cleanup
- Troubleshooting
- Contributing

---

## Overview

This monorepo contains multiple independent Terraform projects targeting AWS. You can pick any folder, run `terraform init/plan/apply`, and see the pattern in action. Highlights:

- S3 static website hosting (with optional Route53)
- CloudFront + Lambda@Edge (Python) auth demo
- ECS patterns with ALB/ASG/networking modules
- VPC, ALB, EC2, RDS two‑tier references
- Remote state backends (AWS S3, Terraform Cloud)
- Foundational Terraform examples (variables, outputs)

## Prerequisites

- Terraform CLI (1.5+ recommended)
- AWS CLI configured with at least one profile
- An AWS account with permissions for the project you want to run

Optional but helpful:
- A code editor (VS Code)
- Basic familiarity with Terraform & AWS

## How to run any project (PowerShell)

Use these repeatable steps for any folder in this repo.

```powershell
# 1) Choose a project folder
cd c:\Users\MaxwellAdomako\amalitech\learning-projects\terraform_repo\<project-folder>

# 2) Select (optional) the AWS profile you want to use
$env:AWS_PROFILE = "<your-profile>"   # e.g., "awscc" or "default"

# 3) Initialize and review the plan
terraform init
terraform plan

# 4) Apply
terraform apply   # add -auto-approve if you prefer non-interactive

# 5) Tear down when done (avoid costs)
terraform destroy # add -auto-approve to skip prompts
```

Notes:
- Many projects default to the `us-east-1` region; check project variables for overrides.
- Lambda@Edge functions must exist in `us-east-1` per AWS requirements.

## Project catalog

Below is a quick map of notable folders and what they do. It isn’t exhaustive, but it will get you oriented fast:

- `secure-pictures-site/`
  - CloudFront + Lambda@Edge authentication demo (Python) with S3 website origin. Includes protected gallery concept, security headers, and Unsplash image links. Start here for an end‑to‑end modern example.
- `lab-work-2/`
  - S3 static website hosting with optional Route53 configuration. Great starter for website hosting.
- `04-variables_and_outputs/`
  - Focused examples showing Terraform variables, outputs, tfvars files, and composition.
- `02-overview/`
  - Minimal Terraform intro example for orientation.
- `1-tier-infras/`
  - One‑tier baseline infrastructure; includes backend options (`aws-backend/`, `terraform-cloud-backend/`) and a simple web‑app.
- `tera-two-tier/`, `two-tier-project/`, `tier-two-project-2/`
  - Two‑tier application patterns (VPC, ALB, EC2/ASG, RDS). Useful as a foundation for many workloads.
- `aws-ecs-project-1/`, `ecs-project-1/`
  - ECS patterns with modular breakdown: `alb/`, `asg/`, `compute/`, `networking/`, etc. Use these to explore containerized deployments.
- `learn-terra/`, `my_first_tf/`
  - Early learning sandboxes and simple compositions.
- `ms-365-terra-version/`
  - Project template with reusable modules: budgets, compute, networking, security-groups, notifications.
- `terraform-import/`
  - Import demonstrations for migrating existing AWS resources into Terraform state.
- `test_aws_services/`
  - Discrete service tests (e.g., S3, ASG) to explore provider behavior and plans.
- `abishek/terraform-zero-to-hero/`
  - Day‑by‑day learning series (Day‑1 … Day‑8) with incremental Terraform patterns.

If a folder includes a `README.md`, read it first—it will contain project‑specific variables and outputs.

## Costs and cleanup

- Cloud infrastructure costs real money. Keep an eye on active resources.
- Always destroy what you don’t need:

```powershell
terraform destroy
```

- Some AWS features (e.g., CloudFront + Lambda@Edge) can take 15–30 minutes to propagate or tear down globally.

## Troubleshooting

Common issues and quick fixes:

- AccessDenied / wrong account or profile
  - Verify who you are:
    ```powershell
    aws sts get-caller-identity
    ```
  - Pick the right profile for the project:
    ```powershell
    $env:AWS_PROFILE = "awscc"   # example
    ```
- Region mismatches
  - Lambda@Edge must be in `us-east-1`. Some examples assume `us-east-1`.
- S3 versioning or policy errors
  - Usually indicate cross‑account usage or restrictive org policies; run with the same profile that created the bucket.
- CloudFront permission errors
  - Use a profile with `cloudfront:*` permissions, or run the S3‑only parts first.

Each project is independent—if one plan fails due to org policies or permissions, try another folder or adjust the profile/region.

## Contributing

- Add new projects under a clearly named folder
- Include a minimal `README.md` per project describing:
  - What it does
  - Prerequisites/variables
  - How to run and destroy
  - Notable costs and caveats
- Prefer modules for reusable components
- Keep provider versions pinned where appropriate

---

Happy Terraforming! If you’re looking for a guided, end‑to‑end sample, start with `secure-pictures-site/` and follow its README for a modern CDN‑fronted, serverless authentication demo.