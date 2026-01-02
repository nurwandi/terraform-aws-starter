########## Global VPC Configuration ##########
###############################################

vpc_id             = "" # Leave empty to create new VPC, or specify existing VPC ID
public_subnet_ids  = [] # Leave empty when creating new VPC
private_subnet_ids = [] # Leave empty when creating new VPC

########## VPC Module Configuration ##########
##############################################

vpc_cidr_block       = "10.1.0.0/16"                                             # TODO: Your VPC CIDR
availability_zones   = ["ap-southeast-3a", "ap-southeast-3b", "ap-southeast-3c"] # TODO: Match your region
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
enable_dns_support   = true
enable_dns_hostnames = true
single_nat_gateway   = true # Production: HA with NAT per AZ

enable_flow_logs         = true # Production: Enable for compliance
flow_logs_destination    = "s3"
flow_logs_retention_days = 30
flow_logs_s3_bucket_arn  = "" # TODO: Your S3 bucket ARN for flow logs

########## EKS Configuration ##########
#######################################

cluster_name                         = "production-eks" # TODO: Your cluster name
cluster_version                      = "1.31"
auto_mode_enabled                    = true # true = EKS Auto Mode, false = Managed Node Groups
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = false # Production: Private only for security
cluster_endpoint_public_access_cidrs = []
enable_cluster_encryption            = true
enabled_cluster_log_types            = ["api", "audit", "authenticator"] # Production: Enable logging
cluster_log_retention_days           = 30

node_groups = {
  general = {
    desired_size   = 3 # Production: More nodes for HA
    min_size       = 2
    max_size       = 10
    instance_types = ["t3.large"] # Production: Larger instances
    capacity_type  = "ON_DEMAND"
    disk_size      = 50 # Production: More storage
    labels = {
      role = "general"
    }
    taints = []
  }
}

enable_vpc_cni        = true
enable_coredns        = true
enable_kube_proxy     = true
enable_ebs_csi_driver = true

########## ALB Configuration ##########
#######################################

alb_name                       = "production-alb" # TODO: Your ALB name
alb_internal                   = false
alb_enable_deletion_protection = true          # Production: Prevent accidental deletion
alb_allowed_cidr_blocks        = ["0.0.0.0/0"] # TODO: Restrict for security

alb_enable_access_logs = true # Production: Enable for compliance
alb_access_logs_bucket = ""   # TODO: Your S3 bucket for ALB logs
alb_access_logs_prefix = "alb-logs"

alb_enable_waf      = true # Production: Enable WAF for security
alb_waf_web_acl_arn = ""   # TODO: Your WAF Web ACL ARN

alb_enable_http_listener   = true
alb_http_redirect_to_https = true # Production: Redirect HTTP to HTTPS

alb_enable_https_listener = true # Production: HTTPS enabled
alb_ssl_certificate_arn   = ""   # TODO: Your ACM certificate ARN
alb_ssl_policy            = "ELBSecurityPolicy-TLS13-1-2-2021-06"

alb_target_groups = {
  default = {
    port                 = 80
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 300
    health_check = {
      enabled             = true
      healthy_threshold   = 3
      unhealthy_threshold = 3
      timeout             = 5
      interval            = 30
      path                = "/"
      matcher             = "200"
      protocol            = "HTTP"
    }
    stickiness = {
      enabled         = false
      type            = "lb_cookie"
      cookie_duration = 86400
      cookie_name     = ""
    }
  }
}

alb_listener_rules = {} # OPTIONAL: Add path-based or host-based routing

########## EC2 Configuration ##########
#######################################

ec2_name          = "production-bastion" # TODO: Your instance name
ec2_subnet_id     = ""                   # TODO AFTER VPC: Use output from module.vpc.private_subnet_ids[0]
ec2_instance_type = "t3.small"           # Production: Larger instance
ec2_key_name      = null                 # OPTIONAL: Specify key pair for SSH, or keep null for SSM-only

ec2_enable_ssm            = true
ec2_create_security_group = true

ec2_security_group_rules = {
  ssh_from_vpc = {
    type        = "ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"] # SSH from VPC CIDR
    description = "Allow SSH from VPC"
  }
  ssh_external = {
    type        = "ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict to your IP for security
    description = "Allow SSH from external"
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

ec2_root_volume_size      = 50 # Production: More storage
ec2_root_volume_type      = "gp3"
ec2_root_volume_encrypted = true
ec2_associate_public_ip   = false

########## S3 Configuration ##########
#######################################

s3_bucket_name         = "my-temporary-bucket-03012026" # TODO: Must be globally unique
s3_force_destroy       = false                          # Production: Keep false (prevent accidental deletion)
s3_versioning_enabled  = false                          # Production: Enable versioning for data protection
s3_block_public_access = true                           # Keep true for security
s3_kms_master_key_id   = null                           # OPTIONAL: Specify KMS key ARN for KMS encryption, null for AES256

# Smart Log Lifecycle (includes transitions, expiration, and multipart cleanup)
s3_lifecycle_rules = {
  enabled                         = true # Enable lifecycle rules
  filter_prefix                   = ""   # TODO: Prefix to apply lifecycle ("" = all objects, "logs/" = logs only)
  standard_ia_days                = 30   # TODO: Days to transition to Standard-IA (min: 30)
  glacier_ir_days                 = 90   # TODO: Days to transition to Glacier Instant Retrieval
  deep_archive_days               = 365  # TODO: Days to transition to Deep Archive (cost-optimized: 365)
  expiration_days                 = 2555 # TODO: Days to delete objects (7 years for compliance)
  abort_incomplete_multipart_days = 7    # TODO: Days to cleanup incomplete multipart uploads
}

s3_tags = {
  Project = "Production App"
  Purpose = "Application Logs"
}
