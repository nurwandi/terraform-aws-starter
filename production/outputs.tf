output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "List of NAT Gateway public IPs"
  value       = module.vpc.nat_gateway_public_ips
}

output "default_security_group_id" {
  description = "The ID of the default security group"
  value       = module.vpc.default_security_group_id
}

########## EKS Outputs ##########
#################################

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider_issuer" {
  description = "OIDC issuer URL without protocol"
  value       = module.eks.oidc_provider_issuer
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_groups" {
  description = "Map of node group attributes"
  value       = module.eks.node_groups
}

output "eks_auto_mode_enabled" {
  description = "Whether EKS Auto Mode is enabled"
  value       = module.eks.auto_mode_enabled
}

########## ALB Outputs ##########
#################################

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route53 alias records)"
  value       = module.alb.alb_zone_id
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = module.alb.alb_arn
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = module.alb.security_group_id
}

output "alb_target_group_arns" {
  description = "Map of target group ARNs"
  value       = module.alb.target_group_arns
}

########## EC2 Outputs ##########
#################################

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "ec2_private_ip" {
  description = "EC2 private IP address"
  value       = module.ec2.private_ip
}

output "ec2_public_ip" {
  description = "EC2 public IP address (if assigned)"
  value       = module.ec2.public_ip
}

output "ec2_ssm_connect_command" {
  description = "AWS CLI command to connect via SSM Session Manager"
  value       = module.ec2.ssm_connect_command
}
