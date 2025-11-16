########## Global VPC Configuration ##########
###############################################
# Use these variables if you want to use an EXISTING VPC instead of creating a new one
# Leave vpc_id empty ("") to create a new VPC using the module

variable "vpc_id" {
  description = "Existing VPC ID (leave empty to create new VPC)"
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "List of existing public subnet IDs (required if using existing VPC)"
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "List of existing private subnet IDs (required if using existing VPC)"
  type        = list(string)
  default     = []
}

########## VPC Module Configuration ##########
##############################################
# Use these variables if you want to CREATE a new VPC

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

# NAT Gateway Configuration
variable "single_nat_gateway" {
  description = "Use single NAT Gateway (true) or one per AZ (false)"
  type        = bool
  default     = true
}

# VPC Flow Logs Configuration
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_destination" {
  description = "Flow logs destination (cloudwatch or s3)"
  type        = string
  default     = "cloudwatch"
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs in CloudWatch"
  type        = number
  default     = 7
}

variable "flow_logs_s3_bucket_arn" {
  description = "S3 bucket ARN for flow logs (required if flow_logs_destination is 's3')"
  type        = string
  default     = ""
}

# EKS Configuration
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "auto_mode_enabled" {
  description = "Enable EKS Auto Mode (if true, managed node groups will be skipped)"
  type        = bool
  default     = false
}

# EKS Cluster Endpoint Configuration
variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_cluster_encryption" {
  description = "Enable envelope encryption of Kubernetes secrets"
  type        = bool
  default     = true
}

# EKS Logging Configuration
variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = []
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# EKS Node Groups Configuration
variable "node_groups" {
  description = "Map of managed node group configurations (ignored if auto_mode_enabled = true)"
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
    capacity_type  = string
    disk_size      = number
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {
    general = {
      desired_size   = 2
      min_size       = 1
      max_size       = 5
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 20
      labels = {
        role = "general"
      }
      taints = []
    }
  }
}

# EKS Add-ons Configuration
variable "enable_vpc_cni" {
  description = "Enable VPC CNI add-on"
  type        = bool
  default     = true
}

variable "enable_coredns" {
  description = "Enable CoreDNS add-on"
  type        = bool
  default     = true
}

variable "enable_kube_proxy" {
  description = "Enable kube-proxy add-on"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI Driver add-on"
  type        = bool
  default     = true
}

########## ALB Configuration ##########
#######################################

variable "alb_name" {
  description = "Name of the ALB"
  type        = string
  default     = ""
}

variable "alb_internal" {
  description = "Whether the ALB is internal or internet-facing"
  type        = bool
  default     = false
}

variable "alb_enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "alb_enable_http2" {
  description = "Enable HTTP/2"
  type        = bool
  default     = true
}

variable "alb_enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "alb_idle_timeout" {
  description = "Time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "alb_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_enable_access_logs" {
  description = "Enable access logs to S3"
  type        = bool
  default     = false
}

variable "alb_access_logs_bucket" {
  description = "S3 bucket name for access logs"
  type        = string
  default     = ""
}

variable "alb_access_logs_prefix" {
  description = "S3 bucket prefix for access logs"
  type        = string
  default     = ""
}

variable "alb_enable_waf" {
  description = "Enable WAF Web ACL association"
  type        = bool
  default     = false
}

variable "alb_waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  type        = string
  default     = ""
}

variable "alb_enable_http_listener" {
  description = "Enable HTTP listener (port 80)"
  type        = bool
  default     = true
}

variable "alb_http_redirect_to_https" {
  description = "Redirect HTTP to HTTPS"
  type        = bool
  default     = false
}

variable "alb_enable_https_listener" {
  description = "Enable HTTPS listener (port 443)"
  type        = bool
  default     = false
}

variable "alb_ssl_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
  default     = ""
}

variable "alb_ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "alb_target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    port                 = number
    protocol             = string
    target_type          = string
    deregistration_delay = number
    health_check = object({
      enabled             = bool
      healthy_threshold   = number
      unhealthy_threshold = number
      timeout             = number
      interval            = number
      path                = string
      matcher             = string
      protocol            = string
    })
    stickiness = object({
      enabled         = bool
      type            = string
      cookie_duration = number
      cookie_name     = string
    })
  }))
  default = {
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
}

variable "alb_listener_rules" {
  description = "Map of listener rules for routing"
  type = map(object({
    priority = number
    listener = string
    actions = list(object({
      type                        = string
      target_group_key            = string
      redirect_protocol           = string
      redirect_status             = string
      fixed_response_content_type = string
      fixed_response_status_code  = string
      fixed_response_message      = string
    }))
    conditions = list(object({
      type   = string
      values = list(string)
    }))
  }))
  default = {}
}

########## EC2 Configuration ##########
#######################################

variable "ec2_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = ""
}

variable "ec2_subnet_id" {
  description = "Subnet ID for EC2 instance (use private subnet for security)"
  type        = string
  default     = ""
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ec2_key_name" {
  description = "Key pair name for SSH access (optional if using SSM only)"
  type        = string
  default     = null
}

variable "ec2_enable_ssm" {
  description = "Enable SSM Session Manager access"
  type        = bool
  default     = true
}

variable "ec2_create_security_group" {
  description = "Create security group for EC2 instance"
  type        = bool
  default     = true
}

variable "ec2_security_group_rules" {
  description = "Map of security group rules"
  type = map(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  }
}

variable "ec2_root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "ec2_root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

variable "ec2_root_volume_encrypted" {
  description = "Encrypt root volume"
  type        = bool
  default     = true
}

variable "ec2_associate_public_ip" {
  description = "Associate public IP address"
  type        = bool
  default     = false
}
