# EKS Module

This module creates a production-ready Amazon EKS cluster with support for both Auto Mode and Managed Node Groups.

## Features

- ☸️ EKS 1.31 cluster with latest Kubernetes features
- 🤖 EKS Auto Mode support (fully managed compute, storage, networking)
- 👥 Managed Node Groups with auto-scaling
- 🔐 Cluster encryption with AWS KMS
- 📝 CloudWatch Logs integration
- 🔑 IRSA (IAM Roles for Service Accounts) support
- 🔌 Essential add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver

## Usage

```hcl
module "eks" {
  source = "./modules/eks"

  environment    = "production"
  cluster_name   = "production-eks"
  cluster_version = "1.31"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Auto Mode (fully managed) or Managed Node Groups
  auto_mode_enabled = false

  node_groups = {
    general = {
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }

  enable_cluster_encryption = true
  enabled_cluster_log_types = ["api", "audit", "authenticator"]
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
