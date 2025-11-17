variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "region" {
  description = "AWS region (required for VPC endpoints)"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
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

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (true) or one per AZ (false)"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_destination" {
  description = "Flow logs destination (cloudwatch or s3)"
  type        = string
  default     = "cloudwatch"
  validation {
    condition     = contains(["cloudwatch", "s3"], var.flow_logs_destination)
    error_message = "Flow logs destination must be either 'cloudwatch' or 's3'."
  }
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs in CloudWatch (if using CloudWatch)"
  type        = number
  default     = 7
}

variable "flow_logs_s3_bucket_arn" {
  description = "S3 bucket ARN for flow logs (required if flow_logs_destination is 's3')"
  type        = string
  default     = ""
}

variable "enable_eic_endpoint" {
  description = "Enable EC2 Instance Connect Endpoint for secure SSH access without public IPs"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
