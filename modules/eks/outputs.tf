########## Cluster Outputs ##########
######################################

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = aws_eks_cluster.main.status
}

########## Certificate Authority ##########
###########################################

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

########## OIDC Provider ##########
###################################

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "oidc_provider_issuer" {
  description = "OIDC issuer URL without protocol"
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

########## IAM Roles ##########
###############################

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the EKS node groups"
  value       = var.auto_mode_enabled || length(var.node_groups) > 0 ? aws_iam_role.node[0].arn : null
}

output "node_iam_role_name" {
  description = "IAM role name of the EKS node groups"
  value       = var.auto_mode_enabled || length(var.node_groups) > 0 ? aws_iam_role.node[0].name : null
}

########## Node Groups ##########
#################################

output "node_groups" {
  description = "Map of node group attributes"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      id              = v.id
      arn             = v.arn
      status          = v.status
      version         = v.version
      node_group_name = v.node_group_name
    }
  }
}

########## Security Group ##########
####################################

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

########## Auto Mode ##########
###############################

output "auto_mode_enabled" {
  description = "Whether EKS Auto Mode is enabled"
  value       = var.auto_mode_enabled
}

########## Add-ons ##########
#############################

output "addon_vpc_cni_version" {
  description = "Version of VPC CNI addon"
  value       = var.enable_vpc_cni ? aws_eks_addon.vpc_cni[0].addon_version : null
}

output "addon_coredns_version" {
  description = "Version of CoreDNS addon"
  value       = var.enable_coredns ? aws_eks_addon.coredns[0].addon_version : null
}

output "addon_kube_proxy_version" {
  description = "Version of kube-proxy addon"
  value       = var.enable_kube_proxy ? aws_eks_addon.kube_proxy[0].addon_version : null
}

output "addon_ebs_csi_driver_version" {
  description = "Version of EBS CSI Driver addon"
  value       = var.enable_ebs_csi_driver ? aws_eks_addon.ebs_csi_driver[0].addon_version : null
}

########## Encryption ##########
################################

output "cluster_encryption_key_arn" {
  description = "KMS key ARN used for cluster encryption"
  value       = var.enable_cluster_encryption ? aws_kms_key.eks[0].arn : null
}
