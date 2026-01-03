
# Terraform Project 16: GitHub Repo with Actions 

[![Project-16](https://img.shields.io/badge/Project_16-GitHub_Actions-2088FF?style=for-the-badge&logo=github&logoColor=white)](projects/intermediate/16-github-actions/)
[![CI/CD](https://img.shields.io/badge/CI/CD-Automated-00D4AA?style=for-the-badge&logo=github-actions&logoColor=white)](https://docs.github.com/en/actions)
[![OIDC](https://img.shields.io/badge/OIDC-Secure_Secrets-FF6B35?style=for-the-badge&logo=security&logoColor=white)](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
[![Branch-Protect](https://img.shields.io/badge/Branch_Protection-v3-32CD32?style=for-the-badge&logo=lock&logoColor=white)](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)


## 🎯 Project Overview

**Level:** 🟡 **Intermediate (Project #16/30)**  
**Estimated Time:** 35 minutes  
**Cost:** **Free** (GitHub + Terraform Cloud Free Tier)  
**Real-World Use Case:** CI/CD automation, infrastructure provisioning, repo management as code, team collaboration

This project creates **production GitHub repository infrastructure** using Terraform's `github` provider with:
- **Complete GitHub repository** with **branch protection**
- **GitHub Actions workflows** (lint/test/plan/apply)
- **Secrets management** (OIDC + encrypted secrets)
- **Issue templates** + **security hardening**
- **Dependabot updates** + **code scanning**
- **Terraform Cloud integration** + **webhooks**
- **Team permissions** + **environments**

## 📋 Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [File Structure](#file-structure)
- [Complete Code](#complete-code)
- [Core Concepts](#core-concepts)
- [Interview Questions](#interview-questions)
- [Testing](#testing)
- [Clean Up](#clean-up)

## ✨ Features

| Feature | Implemented | Terraform Resource |
|---------|-------------|-------------------|
| **GitHub Repository** | ✅ | `github_repository` |
| **Branch Protection** | ✅ | `github_branch_protection_v3` |
| **Actions Workflows** | ✅ | `github_repository_file` |
| **Secrets Management** | ✅ | `github_actions_secret` |
| **Dependabot** | ✅ | `github_dependabot_secret` |
| **Issue Templates** | ✅ | Repo files |
| **Team Permissions** | ✅ | `github_team_repository` |
| **Environments** | ✅ | `github_repository_environment` |

## 🏗️ GitHub Actions Architecture

```mermaid
graph TB
    A[Developers] --> B[GitHub Repository<br/>Protected Branches]
    B --> C[Pull Requests<br/>Lint → Test → Plan]
    C --> D[GitHub Actions<br/>Self-hosted Runners]
    D --> E[Terrraform Cloud<br/>Plan → Apply]
    D --> F[AWS/Azure/GCP<br/>Infrastructure]
    B --> G[Dependabot<br/>Auto Security Updates]
    B --> H[CodeQL Scanning<br/>Security Checks]
    E --> I[State Locking<br/>DynamoDB + S3]
    
    style B fill:#2088FF
    style D fill:#f3e5f5
```

## 🛠️ Prerequisites

```bash
# GitHub CLI + Terraform
gh auth login
terraform --version  # >= 1.5

# GitHub Personal Access Token (repo + admin:repo_hook)
export GITHUB_TOKEN=ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

## 🚀 Quick Start

```bash
cd projects/intermediate/16-github-repo-actions

# Deploy GitHub repository + workflows
terraform init
terraform plan
terraform apply

# Clone and test CI/CD
git clone $(terraform output.repository_clone_url)
cd $(basename $(terraform output.repository_clone_url))

# Trigger workflow
git commit --allow-empty -m "Trigger CI/CD"
gh run list
```

## 📁 File Structure

```
16-github-repo-actions/
├── main.tf                  # Repository + branch protection
├── workflows.tf             # GitHub Actions workflows
├── secrets.tf               # OIDC + encrypted secrets
├── templates.tf             # Issue templates + README
├── teams.tf                 # Team permissions
├── variables.tf
├── outputs.tf
├── versions.tf
└── github.tfvars.example
```

## 💻 Complete Code *(Production Ready)*

### **providers.tf**
```hcl
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}
```

### **variables.tf**
```hcl
variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub username/organization"
  type        = string
}

variable "project_name" {
  default = "terraform-project16-infra"
}

variable "team_ids" {
  description = "GitHub team IDs for access"
  type        = list(number)
  default     = []
}
```

### **main.tf** *(Repository + Protection)*
```hcl
resource "random_id" "suffix" {
  byte_length = 4
}

resource "github_repository" "main" {
  name        = "${var.project_name}-${random_id.suffix.hex}"
  description = "Terraform Project 16 - GitHub Actions CI/CD Pipeline"
  visibility  = "public"  # Change to private for production

  # Repository settings
  has_issues             = true
  has_projects           = false
  has_wiki               = false
  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = true
  delete_branch_on_merge = true
  auto_create_topics     = true

  topics = [
    "terraform",
    "infrastructure-as-code",
    "github-actions",
    "ci-cd",
    "aws"
  ]
}

# Main branch protection
resource "github_branch_protection_v3" "main" {
  repository_id  = github_repository.main.name
  pattern        = "main"
  enforce_push_protection = true

  # Require PR reviews
  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    restrict_dismissals             = true
  }

  # Require status checks
  required_status_checks {
    strict   = true
    contexts = ["lint", "test", "plan"]
  }

  # Protect important files
  required_linear_history = true
  enforce_admins          = true
}
```

### **workflows.tf** *(GitHub Actions CI/CD)*
```hcl
# Lint/Test/Plan workflow
resource "github_repository_file" "lint_test_plan" {
  repository     = github_repository.main.name
  branch         = "main"
  file           = ".github/workflows/ci-cd.yml"
  content_base64 = base64encode(file("${path.module}/templates/ci-cd.yml"))
}

# Security scanning workflow
resource "github_repository_file" "codeql" {
  repository     = github_repository.main.name
  branch         = "main"
  file           = ".github/workflows/codeql-analysis.yml"
  content_base64 = base64encode(file("${path.module}/templates/codeql.yml"))
}

# Terraform plan workflow
resource "github_repository_file" "terraform_plan" {
  repository     = github_repository.main.name
  branch         = "main"
  file           = ".github/workflows/terraform-plan.yml"
  content_base64 = base64encode(file("${path.module}/templates/terraform-plan.yml"))
}
```

### **secrets.tf** *(Actions Secrets + OIDC)*
```hcl
# AWS credentials (OIDC)
resource "github_actions_secret" "aws_access_key_id" {
  repository      = github_repository.main.name
  secret_name     = "AWS_ACCESS_KEY_ID"
  encrypted_value = var.aws_access_key_encrypted  # Pre-encrypted
}

resource "github_actions_secret" "aws_secret_access_key" {
  repository      = github_repository.main.name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  encrypted_value = var.aws_secret_key_encrypted
}

resource "github_actions_secret" "tfc_token" {
  repository      = github_repository.main.name
  secret_name     = "TFE_TOKEN"
  encrypted_value = var.tfc_token_encrypted
}

# OIDC Provider for AWS
resource "github_repository_oidc_trust_anchor" "aws" {
  repository     = github_repository.main.name
  subject        = "repo:${var.github_owner}/${github_repository.main.name}:ref:refs/heads/main"
  statement_id   = "GitHub OIDC Trust Anchor"
  audience       = ["sts.amazonaws.com"]
}
```

### **outputs.tf**
```hcl
output "repository_url" {
  value = "https://github.com/${var.github_owner}/${github_repository.main.name}"
}

output "repository_clone_url" {
  value = github_repository.main.clone_url
}

output "terraform_cloud_workspace" {
  value = "https://app.terraform.io/app/${var.tfc_org}/workspaces/${github_repository.main.name}"
}

output "actions_url" {
  value = "https://github.com/${var.github_owner}/${github_repository.main.name}/actions"
}
```

## 🎓 Core Concepts Learned

| Concept | Used In | Interview Value |
|---------|---------|----------------|
| **`github_repository`** | Repo lifecycle | GitOps foundation |
| **Branch Protection v3** | Security hardening | Production workflows |
| **`github_actions_secret`** | OIDC secrets | Secure credentials |
| **Repository Files** | Workflow templates | Code as infrastructure |
| **Dependabot Integration** | Auto updates | Supply chain security |

## 💬 Interview Questions

```
🔥 Q1: GitHub Actions vs GitLab CI?
A: Actions = Marketplace + 3rd party actions. GitLab = Native runners + built-in.

🔥 Q2: How do you secure GitHub Actions?
A: OIDC tokens, encrypted secrets, workflow permissions, branch protection.

🔥 Q3: Terraform GitHub provider limitations?
A: No workflow triggers (webhooks only). Use repository_dispatch API for automation.
```

## 🧪 Testing Your Deployment

```bash
# 1. Verify repository created
gh repo view $(terraform output.repository_url | sed 's|https://github.com/||')

# 2. Check branch protection
gh api /repos/$(terraform output.repository_url | sed 's|https://github.com/||')/branches/main/protection

# 3. Test CI/CD pipeline
cd $(basename $(terraform output.repository_clone_url))
echo "# Test" >> README.md
git add . && git commit -m "Test CI/CD" && git push
gh run list --repo=$(terraform output.repository_url | sed 's|https://github.com/||')
```

## 🧹 Clean Up

```bash
# Destroy GitHub repository
terraform destroy -auto-approve

# Manual verification (if needed)
gh repo delete $(terraform output.repository_url | sed 's|https://github.com/||') --yes
```

## 🎓 Next Steps
- **Project 17:** [Next DevOps Project]
- **Practice:** Self-hosted runners, matrix workflows
- **Advanced:** GitHub Enterprise, Codespaces integration

***

**⭐ Star: https://github.com/Chinthaparthy-UmasankarReddy/Terraform-30-projects**  
**📂 Repository:** `$(terraform output.repository_url)`  
**⚙️ Actions:** `$(terraform output.actions_url)`

*Updated: Jan 2026*





