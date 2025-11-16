# EC2 Module

This module creates an EC2 instance with SSM Session Manager support, custom security groups, and encrypted storage.

## Features

- 🖥️ Amazon Linux 2023 AMI (auto-updated via SSM parameter)
- 🔐 SSM Session Manager enabled (no SSH keys required!)
- 🛡️ Custom security groups with flexible rules
- 💾 Encrypted EBS volumes (gp3)
- 🏷️ Automatic tagging
- 🔑 Optional SSH key support
- 📊 CloudWatch monitoring
- ⚡ IMDSv2 enforced

## Usage

```hcl
module "ec2" {
  source = "./modules/ec2"

  environment = "production"
  name        = "production-bastion"
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.private_subnet_ids[0]

  instance_type = "t3.small"
  enable_ssm    = true  # Enable SSM Session Manager

  # Security Group
  create_security_group = true
  security_group_rules = {
    ssh_from_vpc = {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "Allow SSH from VPC"
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  }

  # Storage
  root_volume_size      = 50
  root_volume_type      = "gp3"
  root_volume_encrypted = true
}
```

## Connecting to Instance

**Using SSM Session Manager (Recommended):**
```bash
aws ssm start-session --target i-xxxxx
```

**Using SSH (if key pair configured):**
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<private-ip>
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
