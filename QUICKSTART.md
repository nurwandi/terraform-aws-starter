# Quick Start Guide (5-10 Minutes)

Get your AWS infrastructure running in under 10 minutes!

## Prerequisites Checklist

Before you start, make sure you have:

- ✅ **AWS Account** with administrative access
- ✅ **Terraform** >= 1.0 installed ([Install Guide](https://developer.hashicorp.com/terraform/install))
- ✅ **AWS CLI** installed and configured ([Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- ✅ **S3 Bucket** for Terraform state (we'll create this in Step 1)
- ✅ **SSH access** to GitHub (if cloning via SSH)

**Verify installations**:
```bash
terraform --version  # Should be >= 1.0
aws --version        # Should show AWS CLI version
aws sts get-caller-identity  # Should show your AWS account info
```

---

## Step 1: Create S3 Bucket for Terraform State

```bash
# Replace with your desired bucket name and region
aws s3 mb s3://my-terraform-state-bucket --region us-east-1

# Enable versioning (recommended for state recovery)
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled
```

**Note**: S3 bucket names must be globally unique!

---

## Step 2: Clone Repository

```bash
git clone https://github.com/nurwandi/terraform-aws-starter.git
cd terraform-aws-starter
```

---

## Step 3: Configure Backend

```bash
cd staging  # or production

# Copy example backend config
cp backend.tfvars.example backend.tfvars

# Edit backend.tfvars with your values
nano backend.tfvars  # or vim, code, etc.
```

**Edit `backend.tfvars`**:
```hcl
bucket  = "my-terraform-state-bucket"  # Your S3 bucket from Step 1
key     = "staging/terraform.tfstate"   # State file path
region  = "us-east-1"                   # Bucket region
profile = "default"                     # Your AWS CLI profile (or leave empty)
```

---

## Step 4: Configure Region and Credentials

⚠️ **CRITICAL**: These 3 places must have matching values!

### 4.1 Check your AWS profile name
```bash
aws configure list-profiles
# Example output: default, sandbox, production
```

### 4.2 Edit `main.tf` (locals section)
```bash
nano main.tf
```

Find the `locals` block and update:
```hcl
locals {
  environment = "staging"
  region      = "us-east-1"  # ⚠️ Must match backend.tfvars region
  profile     = "default"    # ⚠️ Must match backend.tfvars profile (or your AWS profile)

  # ... rest of locals
}
```

### 4.3 Edit `terraform.tfvars` (availability zones)
```bash
nano terraform.tfvars
```

Update availability zones to match your region:
```hcl
# ⚠️ MUST match your region in main.tf!
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
```

**Common regions**:
- **us-east-1**: `["us-east-1a", "us-east-1b", "us-east-1c"]`
- **us-west-2**: `["us-west-2a", "us-west-2b", "us-west-2c"]`
- **ap-southeast-1**: `["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]`
- **eu-west-1**: `["eu-west-1a", "eu-west-1b", "eu-west-1c"]`

---

## Step 5: Initialize Terraform

```bash
terraform init -backend-config=backend.tfvars
```

**Expected output**:
```
Initializing modules...
Initializing the backend...
Successfully configured the backend "s3"!
Terraform has been successfully initialized!
```

---

## Step 6: Review Configuration (Optional but Recommended)

Adjust values in `terraform.tfvars` based on your needs:

```hcl
# VPC Configuration
vpc_cidr_block     = "10.0.0.0/16"  # ADJUST if needed
single_nat_gateway = true            # true = cheaper, false = HA

# EKS Configuration
cluster_name      = "staging-eks"    # ADJUST: Your cluster name
auto_mode_enabled = false            # true = EKS Auto Mode, false = Managed Node Groups

# For EC2 and ALB, leave as-is for now (can be deployed later)
```

---

## Step 7: Deploy Infrastructure

### Option A: Deploy Everything at Once (Fastest)

```bash
# Review what will be created
terraform plan

# Deploy all modules
terraform apply
# Type 'yes' when prompted
```

**Deployment time**: ~15-20 minutes (mostly EKS cluster creation)

### Option B: Deploy Step-by-Step (More Control)

```bash
# 1. Deploy VPC first (required)
terraform apply -target=module.vpc
# Type 'yes' when prompted

# 2. Get VPC outputs
terraform output vpc_id
terraform output private_subnet_ids

# 3. Update terraform.tfvars with subnet ID (for EC2)
# ec2_subnet_id = "subnet-xxxxx"  # Use first private subnet ID

# 4. Deploy EKS
terraform apply -target=module.eks
# Type 'yes' when prompted

# 5. Deploy ALB (optional)
terraform apply -target=module.alb

# 6. Deploy EC2 (optional)
terraform apply -target=module.ec2
```

---

## Step 8: Verify Deployment

```bash
# Get all outputs
terraform output

# Verify VPC
terraform output vpc_id
terraform output public_subnet_ids
terraform output private_subnet_ids

# Verify EKS
terraform output eks_cluster_name
terraform output eks_cluster_endpoint

# Configure kubectl (if EKS was deployed)
aws eks update-kubeconfig --region us-east-1 --name staging-eks --profile default

# Test kubectl
kubectl get nodes
```

---

## Step 9: Connect to Resources

### Connect to EC2 via SSM Session Manager (No SSH Key Needed!)

```bash
# Get EC2 instance ID
terraform output ec2_instance_id

# Connect via SSM
aws ssm start-session --target i-xxxxx --profile default
```

### Access EKS Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name staging-eks \
  --profile default

# Verify connection
kubectl get svc
kubectl get nodes
```

### Access ALB

```bash
# Get ALB DNS name
terraform output alb_dns_name

# Test (HTTP)
curl http://<alb-dns-name>
```

---

## Troubleshooting

### ❌ Error: "No valid credential sources found"

**Solution**: Configure AWS CLI
```bash
aws configure --profile default
# Enter your Access Key ID, Secret Access Key, region
```

### ❌ Error: "Invalid availability zone"

**Solution**: Your `availability_zones` in `terraform.tfvars` doesn't match your region.

Check available AZs:
```bash
aws ec2 describe-availability-zones --region us-east-1 --query 'AvailabilityZones[].ZoneName'
```

Update `terraform.tfvars`:
```hcl
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]  # Must match region!
```

### ❌ Error: "Backend bucket does not exist"

**Solution**: Create the S3 bucket first (see Step 1)
```bash
aws s3 mb s3://my-terraform-state-bucket --region us-east-1
```

### ❌ Error: "ec2_subnet_id must not be empty"

**Solution**: After VPC is deployed, update `terraform.tfvars`:
```bash
# Get subnet ID
terraform output private_subnet_ids

# Edit terraform.tfvars
# ec2_subnet_id = "subnet-xxxxx"  # Use one of the private subnet IDs
```

### ❌ Error: "Profile not found"

**Solution**: Check your AWS profile name
```bash
# List profiles
aws configure list-profiles

# Use correct profile in main.tf locals and backend.tfvars
```

---

## Clean Up (Destroy Infrastructure)

When you're done testing:

```bash
# Destroy all resources (in reverse order)
terraform destroy -target=module.ec2
terraform destroy -target=module.alb
terraform destroy -target=module.eks
terraform destroy -target=module.vpc

# Or destroy everything at once
terraform destroy
# Type 'yes' when prompted
```

**Warning**: This will permanently delete all resources!

---

## Next Steps

- 📖 Read the full [README.md](README.md) for detailed documentation
- 🔧 Customize modules in `modules/` directory
- 🏗️ Deploy to `production` environment
- 🔒 Set up branch protection for `main` branch
- 📝 Review [KNOWLEDGE.md](KNOWLEDGE.md) for architecture decisions

---

## Summary Checklist

Before running `terraform apply`, ensure:

- ✅ S3 bucket created
- ✅ `backend.tfvars` configured with correct bucket, region, profile
- ✅ `main.tf` locals match `backend.tfvars` (region, profile)
- ✅ `terraform.tfvars` availability_zones match region
- ✅ AWS credentials configured (`aws sts get-caller-identity` works)
- ✅ Terraform initialized (`terraform init -backend-config=backend.tfvars`)

**If all checked**, you're ready to deploy! 🚀

---

**Questions or issues?** Open an issue on [GitHub](https://github.com/nurwandi/terraform-aws-starter/issues)
