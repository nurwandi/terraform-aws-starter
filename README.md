<p align="center">
  <h1 align="center">Terraform AWS Starter</h1>
</p>

<p align="center">
  <img src="https://readme-typing-svg.demolab.com/?lines=Production-ready+AWS+Infrastructure&font=Fira%20Code&center=true&width=500&height=50&color=FF9900&pause=1000" alt="Terraform AWS Starter">
</p>

<p align="center">
  <a href="https://www.terraform.io/" alt="Terraform" title="Terraform 1.0+">
    <img src="https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform&logoColor=white&style=for-the-badge"/></a>
  <a href="https://registry.terraform.io/providers/hashicorp/aws/latest" alt="AWS Provider" title="AWS Provider 5.0+">
    <img src="https://img.shields.io/badge/AWS%20Provider-5.0+-FF9900?logo=amazonaws&logoColor=white&style=for-the-badge"/></a>
  <a href="LICENSE" alt="License" title="MIT License">
    <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge"/></a>
</p>

<p align="center">
  Production-ready Terraform boilerplate for AWS with modular, reusable infrastructure components.
</p>

---

## 🚀 Quick Start

**New to this repo?** Follow the **[QUICKSTART.md](QUICKSTART.md)** for a step-by-step guide (5-10 minutes).

**TL;DR** for experienced users:

```bash
# 1. Clone repo
git clone https://github.com/nurwandi/terraform-aws-starter.git
cd terraform-aws-starter/staging

# 2. Setup backend
cp backend.tfvars.example backend.tfvars
# Edit: bucket, region, profile

# 3. Adjust main.tf locals to match backend.tfvars
# region = "us-east-1", profile = "default"

# 4. Adjust terraform.tfvars availability_zones to match region
# availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# 5. Deploy
terraform init -backend-config=backend.tfvars
terraform apply
```

**⚠️ IMPORTANT**: See [QUICKSTART.md](QUICKSTART.md) for detailed configuration requirements!

## Configuration

### Adjusting Values

Edit `terraform.tfvars` in your environment folder. Look for `# ADJUST` comments:

```hcl
# VPC Configuration
vpc_cidr_block     = "10.0.0.0/16" # ADJUST
availability_zones = ["ap-southeast-3a", "ap-southeast-3b", "ap-southeast-3c"] # ADJUST
single_nat_gateway = true # ADJUST: true = single NAT, false = per-AZ

# EKS Configuration
cluster_name       = "staging-eks" # ADJUST
auto_mode_enabled  = false # ADJUST: true = EKS Auto Mode, false = Managed Node Groups
```

## Backend Configuration

### Setup S3 Backend

1. **Create S3 bucket** for Terraform state:
```bash
aws s3 mb s3://your-terraform-state-bucket --region ap-southeast-3
```

2. **Copy and configure backend.tfvars**:
```bash
cp backend.tfvars.example backend.tfvars
```

3. **Edit backend.tfvars**:
```hcl
bucket  = "your-terraform-state-bucket"  # Your S3 bucket
key     = "staging/terraform.tfstate"     # State file path
region  = "ap-southeast-3"                # Bucket region
profile = "default"                       # AWS CLI profile
```

4. **Initialize Terraform**:
```bash
terraform init -backend-config=backend.tfvars
```

**Note:** `backend.tfvars` is gitignored to prevent exposing sensitive configuration.

## Available Modules

### VPC Module
- Public and private subnets across 3 AZs
- NAT Gateway (single or per-AZ)
- VPC Endpoints (S3, DynamoDB)
- Optional VPC Flow Logs

### EKS Module
- EKS Auto Mode or Managed Node Groups
- OIDC Provider for IRSA
- All add-ons enabled (VPC CNI, CoreDNS, kube-proxy, EBS CSI Driver)
- Encryption enabled by default
- Logging optional

### ALB Module
- Application Load Balancer (internet-facing or internal)
- Configurable target groups with health checks
- HTTP and HTTPS listeners (with ACM certificate support)
- Path-based and host-based routing rules
- Security features:
  - Deletion protection enabled by default
  - Security groups managed automatically
  - Optional WAF Web ACL association
  - Optional access logs to S3
- Session stickiness support

### EC2 Module
- General-purpose EC2 instance (bastion, app server, etc.)
- SSM Session Manager enabled by default (no SSH keys needed!)
- Latest Amazon Linux 2023 AMI via SSM parameter
- Fully adjustable instance type, storage, network
- Security features:
  - Encrypted root volume by default
  - IMDSv2 required (security best practice)
  - Managed security groups with multiple CIDR support
  - Optional SSH key pair (SSM recommended)
- GovCloud/China partition support

## Deployment Guide

### Deploy Per Module

**Recommended approach:** Deploy modules individually to have better control.

```bash
cd staging

# 1. Deploy VPC first
terraform plan -target=module.vpc
terraform apply -target=module.vpc

# 2. Deploy EKS (after VPC is ready)
terraform plan -target=module.eks
terraform apply -target=module.eks

# 3. Deploy ALB (optional, uncomment module in main.tf first)
terraform plan -target=module.alb
terraform apply -target=module.alb

# 4. Deploy EC2 (optional, uncomment module in main.tf first)
terraform plan -target=module.ec2
terraform apply -target=module.ec2
```

**Note:** All modules are commented out by default in `main.tf`. Uncomment the module you want to deploy before running terraform.

### Deploy All Modules

```bash
cd staging
terraform plan
terraform apply
```

### Destroy Per Module

```bash
# Destroy in reverse order
terraform destroy -target=module.ec2
terraform destroy -target=module.alb
terraform destroy -target=module.eks
terraform destroy -target=module.vpc
```

## Requirements

- Terraform >= 1.0
- AWS Provider ~> 5.0
- AWS CLI with configured profile
