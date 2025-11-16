variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EC2 instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance"
  type        = string
}

########## Instance Configuration ##########
############################################

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance (overrides ami_ssm_parameter)"
  type        = string
  default     = null
}

variable "ami_ssm_parameter" {
  description = "SSM parameter name to retrieve AMI ID (default: latest Amazon Linux 2023)"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "key_name" {
  description = "Key pair name for SSH access (optional if using SSM Session Manager only)"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = ""
}

variable "user_data_replace_on_change" {
  description = "Recreate instance when user_data changes"
  type        = bool
  default     = false
}

########## Storage Configuration ##########
###########################################

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of root volume (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2", "st1", "sc1"], var.root_volume_type)
    error_message = "Must be gp3, gp2, io1, io2, st1, or sc1."
  }
}

variable "root_volume_iops" {
  description = "IOPS for root volume (only for gp3, io1, io2)"
  type        = number
  default     = 3000
}

variable "root_volume_throughput" {
  description = "Throughput for root volume in MB/s (only for gp3)"
  type        = number
  default     = 125
}

variable "root_volume_encrypted" {
  description = "Encrypt root volume"
  type        = bool
  default     = true
}

variable "ebs_optimized" {
  description = "Enable EBS optimization"
  type        = bool
  default     = true
}

########## Security Group ##########
####################################

variable "create_security_group" {
  description = "Create security group for EC2 instance"
  type        = bool
  default     = true
}

########## Network Configuration ##########
###########################################

variable "associate_public_ip" {
  description = "Associate public IP address"
  type        = bool
  default     = false
}

variable "private_ip" {
  description = "Private IP address (optional, auto-assigned if not specified)"
  type        = string
  default     = null
}

variable "source_dest_check" {
  description = "Enable source/destination checking (disable for NAT instances)"
  type        = bool
  default     = true
}

variable "security_group_rules" {
  description = "Map of security group rules"
  type = map(object({
    type        = string # ingress or egress
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

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach"
  type        = list(string)
  default     = []
}

########## IAM Configuration ##########
#######################################

variable "enable_ssm" {
  description = "Enable SSM Session Manager access (creates IAM role with SSM policy)"
  type        = bool
  default     = true
}

variable "iam_instance_profile_arn" {
  description = "Existing IAM instance profile ARN (if not using auto-created SSM role)"
  type        = string
  default     = ""
}

variable "additional_iam_policies" {
  description = "Additional IAM policy ARNs to attach to instance role"
  type        = list(string)
  default     = []
}

########## Monitoring & Maintenance ##########
##############################################

variable "monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Enable EC2 instance termination protection"
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior (stop or terminate)"
  type        = string
  default     = "stop"

  validation {
    condition     = contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "Must be stop or terminate."
  }
}

variable "metadata_options" {
  description = "Metadata service options (IMDSv2)"
  type = object({
    http_endpoint               = string
    http_tokens                 = string
    http_put_response_hop_limit = number
    instance_metadata_tags      = string
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 required (security best practice)
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
}

########## Tags ##########
##########################

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
