# Terraform Project 2: S3 Bucket with Versioning

[][projects/beginner/02-s3-bucket-versioning/]
[][projects/beginner/02-s3-bucket-versioning/]
[][projects/beginner/02-s3-bucket-versioning/]

## 🎯 Project Overview

**Level:** Beginner (Project #2/30)  
**Estimated Time:** 20 minutes  
**Cost:** **Free** (S3 Standard storage free tier eligible)  
**Terraform:** 1.9.4 | **AWS Provider:** 5.70.1  
**Real-World Use Case:** Static websites, backups, data lakes, asset storage

This project creates a **production-ready S3 bucket** compatible with **AIG/enterprise standards** using Terraform 1.9.4 + AWS 5.70.1:

- Object versioning enabled
- Server-side encryption (SSE-S3)
- Lifecycle policies with `filter` blocks (5.70.1 requirement)
- Ownership controls & public access blocks
- Comprehensive tagging

## 📋 Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [File Structure](#file-structure)
- [Complete Code](#complete-code)
- [Version Compliance](#version-compliance)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Clean Up](#clean-up)

## ✨ Features

| Feature | Implemented | Terraform Resource |
|---------|-------------|-------------------|
| S3 Bucket | ✅ | `aws_s3_bucket` |
| Versioning | ✅ | `aws_s3_bucket_versioning` |
| Ownership Controls | ✅ | `aws_s3_bucket_ownership_controls` |
| Public Access Block | ✅ | `aws_s3_bucket_public_access_block` |
| Encryption | ✅ | `aws_s3_bucket_server_side_encryption_configuration` |
| Lifecycle Rules | ✅ | `aws_s3_bucket_lifecycle_configuration` |
| Tags | ✅ | `tags_all` |

## 🏗️ Architecture

```
┌─────────────────┐
│   Applications  │─── Uploads ───►
└─────────────────┘
          │
          ▼
┌─────────────────────┐
│ S3 Bucket (Secure)  │
│ • Versioning: ON    │
│ • SSE-S3: AES256    │
│ • IA after 30 days  │
│ • Public: BLOCKED   │
│ • Owner Preferred   │
└─────────────────────┘
```

## 🛠️ Prerequisites

```bash
# Verify versions (AIG/Enterprise standard)
terraform version  # Terraform v1.9.4
aws --version      # AWS CLI v2+

# AWS CLI configured
aws s3 ls

# IAM Permissions
- s3:CreateBucket, s3:PutBucket*
- s3:PutObject, s3:GetObject
```

## 🚀 Quick Start

```bash
cd Terraform-30-projects/projects/beginner/02-s3-bucket-versioning

# Initialize (locks to 1.9.4 + 5.70.1)
terraform init

# Plan
terraform plan -var="bucket_name=tf-project2-$(date +%s)"

# Deploy
terraform apply -var="bucket_name=tf-project2-$(date +%s)"
```

## 📁 File Structure

```
02-s3-bucket-versioning/
├── main.tf              # Enterprise-grade S3 (1.9.4/5.70.1)
├── variables.tf         # AIG-compliant variables
├── outputs.tf           # Secure outputs
├── versions.tf          # Locked versions
├── terraform.tfvars     # Defaults
├── test-files/          # Test assets
├── README.md
└── .gitignore
```

## 📝 Complete Code

### **versions.tf** (AIG/Enterprise Lockfile)
```hcl
terraform {
  required_version = "~> 1.9.0"  # 1.9.4 compatible
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"  # 5.70.1 (AIG standard)
    }
  }
}
```

### **main.tf** (Production-Ready for 5.70.1)
```hcl
provider "aws" {
  region = var.aws_region
}

# S3 Bucket
resource "aws_s3_bucket" "project_bucket" {
  bucket = var.bucket_name

  tags = merge(var.default_tags, {
    Name        = var.bucket_name
    Environment = var.environment
    Project     = "Terraform-30-Projects"
  })
}

# Ownership Controls (5.70.1 requirement)
resource "aws_s3_bucket_ownership_controls" "project_bucket" {
  bucket = aws_s3_bucket.project_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block All Public Access (Security Best Practice)
resource "aws_s3_bucket_public_access_block" "project_bucket" {
  bucket = aws_s3_bucket.project_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "project_bucket_versioning" {
  bucket = aws_s3_bucket.project_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "project_bucket_encryption" {
  bucket = aws_s3_bucket.project_bucket.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle Policy (5.70.1 filter requirement)
resource "aws_s3_bucket_lifecycle_configuration" "project_bucket_lifecycle" {
  bucket = aws_s3_bucket.project_bucket.id
  
  rule {
    id     = "intelligent-archiving"
    status = "Enabled"
    
    filter {
      prefix = ""  # Required in 5.70.1+
    }
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}
```

### **variables.tf**
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique bucket name"
  type        = string
  
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 chars, lowercase, numbers, periods, hyphens."
  }
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "default_tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Owner     = "Learning"
  }
}
```

### **outputs.tf**
```hcl
output "bucket_name" {
  description = "Bucket name"
  value       = aws_s3_bucket.project_bucket.bucket
}

output "bucket_arn" {
  description = "Bucket ARN"
  value       = aws_s3_bucket.project_bucket.arn
}

output "bucket_id" {
  description = "Bucket ID"
  value       = aws_s3_bucket.project_bucket.id
}
```

## ✅ Version Compliance (1.9.4 + 5.70.1)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Terraform `~> 1.9.0` | ✅ | AIG/Financial standard |
| AWS `~> 5.70` | ✅ | Pre-6.x, full S3 v2 support |
| `filter` blocks | ✅ | Lifecycle policy fix |
| Ownership controls | ✅ | No deprecated ACLs |
| Public access blocked | ✅ | Enterprise security |

## 🧪 Testing

```bash
BUCKET=$(terraform output -raw bucket_name)

# Upload test file
echo "Terraform 1.9.4 + AWS 5.70.1 Success!" > test.txt
aws s3 cp test.txt s3://$BUCKET/

# Upload again (creates version)
echo "Version 2" > test.txt
aws s3 cp test.txt s3://$BUCKET/

# Verify versions
aws s3api list-object-versions --bucket $BUCKET
```

## ⚠️ Troubleshooting (5.70.1 Specific)

| Error | Fix |
|-------|-----|
| `filter required` | Add `filter { prefix = "" }` to lifecycle rules |
| `ACL deprecated` | Use `aws_s3_bucket_ownership_controls` |
| `Public policy blocked` | ✅ Already blocked (security win) |

**Quick Fix Command:**
```bash
terraform validate && terraform fmt -check
```
## 🧹 Clean Up

```bash
terraform destroy -auto-approve -var="bucket_name=$BUCKET"
```

## 🎓 Interview Prep

**Q: "What versions for enterprise S3?"**
**A: "Terraform 1.9.4 with AWS 5.70.1 - stable, full S3 v2 resource support, AIG compliance certified."**

## 📄 License
MIT License - Free for learning/portfolio

***

**⭐ Star:** [Terraform-30-projects](https://github.com/Chinthaparthy-UmasankarReddy/Terraform-30-projects)  
**Updated:** Jan 2026 | **Terraform 1.9.4** | **AWS 5.70.1**

[1](https://img.shields.io/badge/Project_2-S3_Versioning-FF9900?style=for-the-badge&logo=amazon-s3&logoColor=white)
[2](https://img.shields.io/bad)
