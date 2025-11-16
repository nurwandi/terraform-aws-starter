variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS cluster (private subnets recommended)"
  type        = list(string)
}

########## Auto Mode ##########
###############################

variable "auto_mode_enabled" {
  description = "Enable EKS Auto Mode (if true, managed node groups will be skipped)"
  type        = bool
  default     = false
}

########## Cluster Configuration ##########
############################################

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

########## Logging ##########
#############################

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable (api, audit, authenticator, controllerManager, scheduler)"
  type        = list(string)
  default     = []
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

########## Node Groups (ignored if auto_mode_enabled = true) ##########
########################################################################

variable "node_groups" {
  description = "Map of managed node group configurations (ignored if auto_mode_enabled = true)"
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
    capacity_type  = string # ON_DEMAND or SPOT
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

########## Add-ons ##########
#############################

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

########## Tags ##########
##########################

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
