########## Instance Outputs ##########
#######################################

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "EC2 instance ARN"
  value       = aws_instance.main.arn
}

output "instance_state" {
  description = "EC2 instance state"
  value       = aws_instance.main.instance_state
}

output "instance_type" {
  description = "EC2 instance type"
  value       = aws_instance.main.instance_type
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.main.ami
}

########## Network Outputs ##########
######################################

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.main.private_ip
}

output "public_ip" {
  description = "Public IP address (if assigned)"
  value       = aws_instance.main.public_ip
}

output "private_dns" {
  description = "Private DNS name"
  value       = aws_instance.main.private_dns
}

output "public_dns" {
  description = "Public DNS name (if assigned)"
  value       = aws_instance.main.public_dns
}

output "subnet_id" {
  description = "Subnet ID where instance is deployed"
  value       = aws_instance.main.subnet_id
}

output "availability_zone" {
  description = "Availability zone where instance is deployed"
  value       = aws_instance.main.availability_zone
}

########## Security Group ##########
####################################

output "security_group_id" {
  description = "Security group ID (if created)"
  value       = var.create_security_group ? aws_security_group.instance[0].id : null
}

output "security_group_arn" {
  description = "Security group ARN (if created)"
  value       = var.create_security_group ? aws_security_group.instance[0].arn : null
}

########## IAM Outputs ##########
#################################

output "iam_role_name" {
  description = "IAM role name (if created)"
  value       = var.enable_ssm && var.iam_instance_profile_arn == "" ? aws_iam_role.instance[0].name : null
}

output "iam_role_arn" {
  description = "IAM role ARN (if created)"
  value       = var.enable_ssm && var.iam_instance_profile_arn == "" ? aws_iam_role.instance[0].arn : null
}

output "iam_instance_profile_name" {
  description = "IAM instance profile name"
  value = var.iam_instance_profile_arn != "" ? var.iam_instance_profile_arn : (
    var.enable_ssm ? aws_iam_instance_profile.instance[0].name : null
  )
}

output "iam_instance_profile_arn" {
  description = "IAM instance profile ARN"
  value = var.iam_instance_profile_arn != "" ? var.iam_instance_profile_arn : (
    var.enable_ssm ? aws_iam_instance_profile.instance[0].arn : null
  )
}

########## SSM Session Manager ##########
#########################################

output "ssm_enabled" {
  description = "Whether SSM Session Manager is enabled"
  value       = var.enable_ssm
}

output "ssm_connect_command" {
  description = "AWS CLI command to connect via SSM Session Manager"
  value       = var.enable_ssm ? "aws ssm start-session --target ${aws_instance.main.id}" : "SSM not enabled"
}

########## Root Volume ##########
#################################

output "root_volume_id" {
  description = "Root volume ID"
  value       = aws_instance.main.root_block_device[0].volume_id
}

output "root_volume_size" {
  description = "Root volume size in GB"
  value       = aws_instance.main.root_block_device[0].volume_size
}

output "root_volume_type" {
  description = "Root volume type"
  value       = aws_instance.main.root_block_device[0].volume_type
}
