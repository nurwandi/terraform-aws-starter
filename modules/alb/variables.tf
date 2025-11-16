variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
}

variable "name" {
  description = "Name of the ALB"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ALB (public subnets recommended for internet-facing ALB)"
  type        = list(string)
}

########## ALB Configuration ##########
#######################################

variable "internal" {
  description = "Whether the ALB is internal or internet-facing"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Enable HTTP/2"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Time in seconds that the connection is allowed to be idle (1-4000)"
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "Idle timeout must be between 1 and 4000 seconds."
  }
}

variable "ip_address_type" {
  description = "Type of IP addresses used by the subnets (ipv4 or dualstack)"
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "Must be ipv4 or dualstack."
  }
}

########## Security Hardening ##########
########################################

variable "drop_invalid_header_fields" {
  description = "Drop invalid HTTP headers to prevent HTTP desync attacks (recommended: true)"
  type        = bool
  default     = true
}

variable "desync_mitigation_mode" {
  description = "HTTP desync mitigation mode (defensive, strictest, monitor)"
  type        = string
  default     = "defensive"

  validation {
    condition     = contains(["defensive", "strictest", "monitor"], var.desync_mitigation_mode)
    error_message = "Must be defensive, strictest, or monitor."
  }
}

variable "preserve_host_header" {
  description = "Preserve the Host header in requests forwarded to targets"
  type        = bool
  default     = false
}

########## Security Group ##########
####################################

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to ALB"
  type        = list(string)
  default     = []
}

########## Access Logs ##########
#################################

variable "enable_access_logs" {
  description = "Enable access logs to S3"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for access logs (required if enable_access_logs = true)"
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "S3 bucket prefix for access logs"
  type        = string
  default     = ""
}

########## WAF ##########
#########################

variable "enable_waf" {
  description = "Enable WAF Web ACL association"
  type        = bool
  default     = false
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN (required if enable_waf = true)"
  type        = string
  default     = ""
}

########## Listeners ##########
###############################

variable "enable_http_listener" {
  description = "Enable HTTP listener (port 80)"
  type        = bool
  default     = true
}

variable "http_redirect_to_https" {
  description = "Redirect HTTP to HTTPS (requires HTTPS listener)"
  type        = bool
  default     = false
}

variable "enable_https_listener" {
  description = "Enable HTTPS listener (port 443)"
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (required if enable_https_listener = true)"
  type        = string
  default     = ""
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "additional_ssl_certificate_arns" {
  description = "Additional ACM certificate ARNs for HTTPS listener (for multiple domains)"
  type        = list(string)
  default     = []
}

########## Target Groups ##########
###################################

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    port                 = number
    protocol             = string
    target_type          = string # instance, ip, lambda, alb
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
      type            = string # lb_cookie or app_cookie
      cookie_duration = number
      cookie_name     = string # Required if type is app_cookie
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

########## Listener Rules ##########
####################################

variable "listener_rules" {
  description = "Map of listener rules for routing (path-based, host-based)"
  type = map(object({
    priority = number
    listener = string # "http" or "https"
    actions = list(object({
      type                        = string # forward, redirect, fixed-response
      target_group_key            = string # Key from target_groups map (for forward action)
      redirect_protocol           = string # HTTP or HTTPS (for redirect action)
      redirect_status             = string # HTTP_301 or HTTP_302 (for redirect action)
      fixed_response_content_type = string # text/plain, text/css, text/html, application/json (for fixed-response)
      fixed_response_status_code  = string # HTTP status code (for fixed-response)
      fixed_response_message      = string # Response body (for fixed-response)
    }))
    conditions = list(object({
      type   = string # path-pattern, host-header, http-header, query-string
      values = list(string)
    }))
  }))
  default = {}
}

########## Tags ##########
##########################

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
