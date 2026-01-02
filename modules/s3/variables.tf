########## Required Variables ##########
#########################################

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase alphanumeric with hyphens, cannot start/end with hyphen."
  }
}

########## Bucket Configuration ##########
##########################################

variable "force_destroy" {
  description = "Allow deletion of bucket with objects (use with caution)"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning on S3 bucket"
  type        = bool
  default     = false
}

variable "block_public_access" {
  description = "Block all public access to the bucket"
  type        = bool
  default     = true
}

########## Encryption Configuration ##########
###############################################

variable "kms_master_key_id" {
  description = "KMS key ID for encryption (leave null for AES256)"
  type        = string
  default     = null
}

########## Lifecycle Configuration ##########
##############################################

variable "lifecycle_rules" {
  description = "Lifecycle configuration for S3 bucket objects"
  type = object({
    enabled                         = bool
    filter_prefix                   = string
    standard_ia_days                = number
    glacier_ir_days                 = number
    deep_archive_days               = number
    expiration_days                 = number
    abort_incomplete_multipart_days = number
  })

  default = {
    enabled                         = true
    filter_prefix                   = ""
    standard_ia_days                = 30
    glacier_ir_days                 = 90
    deep_archive_days               = 365
    expiration_days                 = 2555
    abort_incomplete_multipart_days = 7
  }

  validation {
    condition = (
      var.lifecycle_rules.standard_ia_days < var.lifecycle_rules.glacier_ir_days &&
      var.lifecycle_rules.glacier_ir_days < var.lifecycle_rules.deep_archive_days &&
      var.lifecycle_rules.deep_archive_days < var.lifecycle_rules.expiration_days
    )
    error_message = "Lifecycle transition days must be in ascending order: Standard-IA < Glacier IR < Deep Archive < Expiration."
  }

  validation {
    condition     = var.lifecycle_rules.standard_ia_days >= 30
    error_message = "Minimum 30 days required before transitioning to Standard-IA (AWS requirement)."
  }

  validation {
    condition     = var.lifecycle_rules.abort_incomplete_multipart_days >= 1
    error_message = "Abort incomplete multipart upload days must be at least 1."
  }
}

########## Tags ##########
##########################

variable "tags" {
  description = "Additional tags for the S3 bucket"
  type        = map(string)
  default     = {}
}
