########## ALB Outputs ##########
##################################

output "alb_id" {
  description = "ID of the ALB"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB (for use with CloudWatch metrics)"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route53 alias records)"
  value       = aws_lb.main.zone_id
}

########## Security Group ##########
####################################

output "security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}

output "security_group_arn" {
  description = "Security group ARN of the ALB"
  value       = aws_security_group.alb.arn
}

########## Target Groups ##########
###################################

output "target_group_arns" {
  description = "Map of target group ARNs"
  value = {
    for k, v in aws_lb_target_group.main : k => v.arn
  }
}

output "target_group_arn_suffixes" {
  description = "Map of target group ARN suffixes (for use with CloudWatch metrics)"
  value = {
    for k, v in aws_lb_target_group.main : k => v.arn_suffix
  }
}

output "target_group_names" {
  description = "Map of target group names"
  value = {
    for k, v in aws_lb_target_group.main : k => v.name
  }
}

########## Listeners ##########
###############################

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = var.enable_http_listener ? aws_lb_listener.http[0].arn : null
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = var.enable_https_listener ? aws_lb_listener.https[0].arn : null
}

########## Listener Rules ##########
####################################

output "listener_rule_arns" {
  description = "Map of listener rule ARNs"
  value = {
    for k, v in aws_lb_listener_rule.main : k => v.arn
  }
}
