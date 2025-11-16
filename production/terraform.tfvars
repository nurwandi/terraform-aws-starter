########## Global VPC Configuration ##########
###############################################
# Option 1: Use existing VPC (uncomment and fill values)
# vpc_id             = "vpc-xxxxx"  # Your existing VPC ID
# public_subnet_ids  = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
# private_subnet_ids = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]

# Option 2: Create new VPC (default, leave vpc_id empty)
vpc_id             = ""  # Leave empty to create new VPC
public_subnet_ids  = []  # Leave empty when creating new VPC
private_subnet_ids = []  # Leave empty when creating new VPC

########## VPC Module Configuration ##########
##############################################
# These values are used when creating a NEW VPC (when vpc_id is empty)

vpc_cidr_block     = "10.1.0.0/16" # ADJUST
availability_zones = ["ap-southeast-3a", "ap-southeast-3b", "ap-southeast-3c"] # ADJUST

# Subnet Configuration
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"] # ADJUST
private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"] # ADJUST

# DNS Configuration
enable_dns_support   = true
enable_dns_hostnames = true

# NAT Gateway Configuration
single_nat_gateway = false # ADJUST: true = single NAT (cost-effective), false = per-AZ (HA)

# VPC Flow Logs Configuration
enable_flow_logs         = true # ADJUST
flow_logs_destination    = "s3" # ADJUST: "cloudwatch" or "s3"
flow_logs_retention_days = 30 # ADJUST
flow_logs_s3_bucket_arn  = "arn:aws:s3:::your-production-flow-logs-bucket" # ADJUST: Required if flow_logs_destination is "s3"

# EKS Configuration
cluster_name    = "production-eks" # ADJUST
cluster_version = "1.31" # ADJUST

# EKS Auto Mode (if true, managed node groups will be skipped)
auto_mode_enabled = false # ADJUST: true = EKS Auto Mode, false = Managed Node Groups

# EKS Endpoint Configuration
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = false # ADJUST: true for development/external access
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # ADJUST: Restrict to your IP for security

# EKS Encryption
enable_cluster_encryption = true

# EKS Logging (disabled by default for cost savings)
enabled_cluster_log_types  = [] # ADJUST: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cluster_log_retention_days = 7 # ADJUST

# EKS Node Groups (ignored if auto_mode_enabled = true)
node_groups = {
  general = {
    desired_size   = 3 # ADJUST: Production typically needs more nodes
    min_size       = 2 # ADJUST
    max_size       = 10 # ADJUST
    instance_types = ["t3.large"] # ADJUST: Production typically needs larger instances
    capacity_type  = "ON_DEMAND" # ADJUST: "ON_DEMAND" or "SPOT"
    disk_size      = 50 # ADJUST
    labels = {
      role = "general"
    }
    taints = []
  }
}

# EKS Add-ons (all enabled by default)
enable_vpc_cni        = true
enable_coredns        = true
enable_kube_proxy     = true
enable_ebs_csi_driver = true

########## ALB Configuration ##########
#######################################

alb_name = "production-alb" # ADJUST

# ALB Type
alb_internal = false # ADJUST: true = internal ALB, false = internet-facing

# Security
alb_enable_deletion_protection = true
alb_allowed_cidr_blocks        = ["0.0.0.0/0"] # ADJUST: Restrict to specific IPs/CIDRs for security

# Access Logs (recommended for production)
alb_enable_access_logs = true # ADJUST: Enable for production
alb_access_logs_bucket = "" # ADJUST: S3 bucket name for access logs
alb_access_logs_prefix = "alb-logs" # ADJUST

# WAF (recommended for production)
alb_enable_waf      = true # ADJUST: Enable WAF for production
alb_waf_web_acl_arn = "" # ADJUST: WAF Web ACL ARN

# HTTP Listener
alb_enable_http_listener   = true
alb_http_redirect_to_https = true # ADJUST: Redirect HTTP to HTTPS for production

# HTTPS Listener (recommended for production)
alb_enable_https_listener = true # ADJUST: Enable HTTPS for production
alb_ssl_certificate_arn   = "" # ADJUST: ACM certificate ARN
alb_ssl_policy            = "ELBSecurityPolicy-TLS13-1-2-2021-06" # ADJUST

# Target Groups
alb_target_groups = {
  default = {
    port                 = 80
    protocol             = "HTTP"
    target_type          = "instance" # ADJUST: instance, ip, lambda, alb
    deregistration_delay = 300
    health_check = {
      enabled             = true
      healthy_threshold   = 3
      unhealthy_threshold = 3
      timeout             = 5
      interval            = 30
      path                = "/" # ADJUST: Health check path
      matcher             = "200"
      protocol            = "HTTP"
    }
    stickiness = {
      enabled         = false # ADJUST: Enable for session persistence
      type            = "lb_cookie"
      cookie_duration = 86400
      cookie_name     = ""
    }
  }
}

# Listener Rules (optional, for path-based or host-based routing)
alb_listener_rules = {}
# Example:
# alb_listener_rules = {
#   api = {
#     priority = 100
#     listener = "https"
#     actions = [{
#       type             = "forward"
#       target_group_key = "api"
#       redirect_protocol = ""
#       redirect_status   = ""
#       fixed_response_content_type = ""
#       fixed_response_status_code  = ""
#       fixed_response_message      = ""
#     }]
#     conditions = [{
#       type   = "path-pattern"
#       values = ["/api/*"]
#     }]
#   }
# }

########## EC2 Configuration ##########
#######################################

ec2_name          = "production-bastion" # ADJUST
ec2_subnet_id     = "" # ADJUST: Use module.vpc.private_subnet_ids[0] after VPC is created
ec2_instance_type = "t3.small" # ADJUST: Production typically needs larger instance
ec2_key_name      = null # ADJUST: Your key pair name, or null for SSM-only access

# SSM Session Manager (enabled by default, no SSH key needed!)
ec2_enable_ssm = true

# Security Group
ec2_create_security_group = true
ec2_security_group_rules = {
  # Example: Allow SSH from VPC (if you want SSH access)
  # ssh = {
  #   type        = "ingress"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR
  #   description = "SSH from VPC"
  # }
  egress_all = {
    type        = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

# Storage (production typically needs more storage)
ec2_root_volume_size      = 50 # ADJUST: GB
ec2_root_volume_type      = "gp3" # ADJUST
ec2_root_volume_encrypted = true

# Network
ec2_associate_public_ip = false # ADJUST: true for public subnet, false for private