terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}

locals {
  environment = "lensclause"
  region      = "ap-southeast-3"
  profile     = "lensclause-development"

  # Global VPC ID: Use existing VPC if specified, otherwise use VPC from module
  # If you want to use existing VPC: set vpc_id variable in terraform.tfvars
  # If you want to create new VPC: leave vpc_id empty, module.vpc will be used
  vpc_id             = var.vpc_id != "" ? var.vpc_id : module.vpc.vpc_id
  public_subnet_ids  = var.vpc_id != "" ? var.public_subnet_ids : module.vpc.public_subnet_ids
  private_subnet_ids = var.vpc_id != "" ? var.private_subnet_ids : module.vpc.private_subnet_ids
}

provider "aws" {
  profile = local.profile
  region  = local.region

  default_tags {
    tags = {
      Environment = title(local.environment)
      ManagedBy   = "Terraform"
    }
  }
}

########## VPC ##########
#########################
module "vpc" {
  source = "../modules/vpc"

  environment          = local.environment
  region               = local.region
  vpc_cidr_block       = var.vpc_cidr_block
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  single_nat_gateway   = var.single_nat_gateway

  # Flow logs configuration
  enable_flow_logs         = var.enable_flow_logs
  flow_logs_destination    = var.flow_logs_destination
  flow_logs_retention_days = var.flow_logs_retention_days
  flow_logs_s3_bucket_arn  = var.flow_logs_s3_bucket_arn

  # EC2 Instance Connect Endpoint
  enable_eic_endpoint = var.enable_eic_endpoint
}

########## EKS ##########
#########################
module "eks" {
  source = "../modules/eks"

  environment  = local.environment
  region       = local.region
  cluster_name = var.cluster_name
  vpc_id       = local.vpc_id
  subnet_ids   = local.private_subnet_ids

  # Auto Mode configuration
  auto_mode_enabled = var.auto_mode_enabled

  # Cluster configuration
  cluster_version                      = var.cluster_version
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  enable_cluster_encryption            = var.enable_cluster_encryption

  # Logging configuration
  enabled_cluster_log_types  = var.enabled_cluster_log_types
  cluster_log_retention_days = var.cluster_log_retention_days

  # Node groups (ignored if auto_mode_enabled = true)
  node_groups = var.node_groups

  # Add-ons
  enable_vpc_cni        = var.enable_vpc_cni
  enable_coredns        = var.enable_coredns
  enable_kube_proxy     = var.enable_kube_proxy
  enable_ebs_csi_driver = var.enable_ebs_csi_driver
}

########## ALB (Application Load Balancer) ##########
######################################################
module "alb" {
  source = "../modules/alb"

  environment = local.environment
  name        = var.alb_name
  vpc_id      = local.vpc_id
  subnet_ids  = local.public_subnet_ids

  # ALB Configuration
  internal                         = var.alb_internal
  enable_deletion_protection       = var.alb_enable_deletion_protection
  enable_http2                     = var.alb_enable_http2
  enable_cross_zone_load_balancing = var.alb_enable_cross_zone_load_balancing
  idle_timeout                     = var.alb_idle_timeout

  # Security
  allowed_cidr_blocks = var.alb_allowed_cidr_blocks

  # Access Logs
  enable_access_logs = var.alb_enable_access_logs
  access_logs_bucket = var.alb_access_logs_bucket
  access_logs_prefix = var.alb_access_logs_prefix

  # WAF
  enable_waf      = var.alb_enable_waf
  waf_web_acl_arn = var.alb_waf_web_acl_arn

  # Listeners
  enable_http_listener   = var.alb_enable_http_listener
  http_redirect_to_https = var.alb_http_redirect_to_https
  enable_https_listener  = var.alb_enable_https_listener
  ssl_certificate_arn    = var.alb_ssl_certificate_arn
  ssl_policy             = var.alb_ssl_policy

  # Target Groups
  target_groups = var.alb_target_groups

  # Listener Rules
  listener_rules = var.alb_listener_rules
}

########## IAM Policy for SSM Parameter Store ##########
#########################################################
resource "aws_iam_policy" "ssm_parameters" {
  name        = "AccessToParameterStorePolicy"
  description = "Allow EC2 instances to read SSM parameters for ${local.environment}"
  policy      = file("${path.module}/iam-policy-ssm-parameters.json")
}

########## EC2 Instances ##########
####################################
module "ec2" {
  source   = "../modules/ec2"
  for_each = var.ec2_instances

  environment = local.environment
  name        = "${local.environment}-${each.key}"
  vpc_id      = local.vpc_id
  subnet_id   = each.value.subnet_id != "" ? each.value.subnet_id : local.private_subnet_ids[0]

  # Instance configuration
  instance_type = each.value.instance_type
  ami_id        = try(each.value.ami_id, null) # Ubuntu override if specified
  key_name      = each.value.key_name

  # SSM Session Manager (enabled by default)
  enable_ssm = each.value.enable_ssm

  # Additional IAM policies (SSM Parameter Store for application-services and application-services-ubuntu)
  additional_iam_policies = contains(["application-services", "application-services-ubuntu"], each.key) ? [aws_iam_policy.ssm_parameters.arn] : []

  # Security group
  create_security_group = each.value.create_security_group
  security_group_rules  = each.value.security_group_rules

  # Storage
  root_volume_size      = each.value.root_volume_size
  root_volume_type      = each.value.root_volume_type
  root_volume_encrypted = each.value.root_volume_encrypted

  # Network
  associate_public_ip = each.value.associate_public_ip
}
