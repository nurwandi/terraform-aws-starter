# VPC Module

This module creates a production-ready AWS VPC with public and private subnets across multiple availability zones.

## Features

- 🌐 Multi-AZ deployment for high availability
- 🔒 Public and private subnet separation
- 🌉 NAT Gateway for private subnet internet access
- 📊 Optional VPC Flow Logs (CloudWatch or S3)
- 🏷️ Consistent tagging strategy
- 🔧 Configurable CIDR blocks and subnet ranges

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  environment          = "production"
  vpc_cidr_block       = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_dns_support   = true
  enable_dns_hostnames = true
  single_nat_gateway   = false  # HA with NAT per AZ

  enable_flow_logs         = true
  flow_logs_destination    = "cloudwatch"
  flow_logs_retention_days = 30
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
