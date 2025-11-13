# AWS Terraform Template

Reusable Terraform boilerplate for AWS infrastructure.

## Quick Start

```bash
cd staging

# Setup backend configuration
cp backend.tfvars.example backend.tfvars
# Edit backend.tfvars with your S3 bucket details

# Initialize with backend config
terraform init -backend-config=backend.tfvars

# Deploy
terraform plan
terraform apply
```

## Configuration

### Adjusting Values

Edit `terraform.tfvars` in your environment folder. Look for `# ADJUST` comments:

```hcl
# terraform.tfvars
vpc_cidr_block     = "10.0.0.0/16" # ADJUST
availability_zones = ["ap-southeast-3a", "ap-southeast-3b", "ap-southeast-3c"] # ADJUST
single_nat_gateway = true # ADJUST: true = single NAT, false = per-AZ
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

## Usage Examples

### Deploy VPC Only

```bash
cd staging
terraform init -backend-config=backend.tfvars
terraform plan -target=module.vpc
terraform apply -target=module.vpc
```

### Change VPC Configuration

1. Edit `staging/terraform.tfvars`:
```hcl
vpc_cidr_block = "10.5.0.0/16" # Changed
single_nat_gateway = false # Enable HA mode
```

2. Apply changes:
```bash
terraform plan
terraform apply
```

## Requirements

- Terraform >= 1.0
- AWS Provider ~> 5.0
- AWS CLI with configured profile
