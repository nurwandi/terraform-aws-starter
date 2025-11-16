########## Data Sources ##########
###################################

# AWS partition (for GovCloud/China support)
data "aws_partition" "current" {}

# Get latest Amazon Linux 2023 AMI via SSM parameter
data "aws_ssm_parameter" "ami" {
  count = var.ami_id == null ? 1 : 0
  name  = var.ami_ssm_parameter
}

locals {
  ami_id = coalesce(var.ami_id, try(data.aws_ssm_parameter.ami[0].value, ""))
}

########## Security Group ##########
####################################

# Flatten security group rules to handle multiple CIDR blocks
locals {
  ingress_rules = flatten([
    for rule_key, rule in var.security_group_rules : [
      for idx, cidr in rule.cidr_blocks : {
        rule_key    = rule_key
        cidr_idx    = idx
        cidr_block  = cidr
        description = rule.description
        from_port   = rule.from_port
        to_port     = rule.to_port
        protocol    = rule.protocol
      }
    ] if rule.type == "ingress"
  ])

  ingress_rules_map = {
    for rule in local.ingress_rules :
    "${rule.rule_key}-${rule.cidr_idx}" => rule
  }

  egress_rules = flatten([
    for rule_key, rule in var.security_group_rules : [
      for idx, cidr in rule.cidr_blocks : {
        rule_key    = rule_key
        cidr_idx    = idx
        cidr_block  = cidr
        description = rule.description
        from_port   = rule.from_port
        to_port     = rule.to_port
        protocol    = rule.protocol
      }
    ] if rule.type == "egress"
  ])

  egress_rules_map = {
    for rule in local.egress_rules :
    "${rule.rule_key}-${rule.cidr_idx}" => rule
  }
}

resource "aws_security_group" "instance" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.name}-sg"
  description = "Security group for ${var.name} EC2 instance"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Security group rules - ingress
resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.create_security_group ? local.ingress_rules_map : {}

  security_group_id = aws_security_group.instance[0].id
  description       = each.value.description
  from_port         = each.value.protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.protocol == "-1" ? null : each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_block
}

# Security group rules - egress
resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = var.create_security_group ? local.egress_rules_map : {}

  security_group_id = aws_security_group.instance[0].id
  description       = each.value.description
  from_port         = each.value.protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.protocol == "-1" ? null : each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_block
}

########## IAM Role for SSM ##########
######################################

# IAM role for EC2 instance (with SSM access)
resource "aws_iam_role" "instance" {
  count = var.enable_ssm && var.iam_instance_profile_arn == "" ? 1 : 0

  name = "${var.name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(
    {
      Name        = "${var.name}-instance-role"
      Environment = var.environment
    },
    var.tags
  )
}

# Attach SSM managed policy for Session Manager
resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm && var.iam_instance_profile_arn == "" ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach additional IAM policies
resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.enable_ssm && var.iam_instance_profile_arn == "" ? toset(var.additional_iam_policies) : []

  role       = aws_iam_role.instance[0].name
  policy_arn = each.value
}

# Create instance profile
resource "aws_iam_instance_profile" "instance" {
  count = var.enable_ssm && var.iam_instance_profile_arn == "" ? 1 : 0

  name = "${var.name}-instance-profile"
  role = aws_iam_role.instance[0].name

  tags = merge(
    {
      Name        = "${var.name}-instance-profile"
      Environment = var.environment
    },
    var.tags
  )
}

########## EC2 Instance ##########
##################################

resource "aws_instance" "main" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  # IAM instance profile
  iam_instance_profile = var.iam_instance_profile_arn != "" ? var.iam_instance_profile_arn : (
    var.enable_ssm ? aws_iam_instance_profile.instance[0].name : null
  )

  # Security groups
  vpc_security_group_ids = var.create_security_group ? concat(
    [aws_security_group.instance[0].id],
    var.additional_security_group_ids
  ) : var.additional_security_group_ids

  # Network configuration
  associate_public_ip_address = var.associate_public_ip
  private_ip                  = var.private_ip
  source_dest_check           = var.source_dest_check

  # Storage configuration
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    iops                  = contains(["gp3", "io1", "io2"], var.root_volume_type) ? var.root_volume_iops : null
    throughput            = var.root_volume_type == "gp3" ? var.root_volume_throughput : null
    encrypted             = var.root_volume_encrypted
    delete_on_termination = true
  }

  # EBS optimization
  ebs_optimized = var.ebs_optimized

  # Monitoring
  monitoring = var.monitoring

  # User data
  user_data                   = var.user_data != "" ? var.user_data : null
  user_data_replace_on_change = var.user_data_replace_on_change

  # Termination protection
  disable_api_termination = var.disable_api_termination

  # Shutdown behavior
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  # Metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = var.metadata_options.http_endpoint
    http_tokens                 = var.metadata_options.http_tokens
    http_put_response_hop_limit = var.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.metadata_options.instance_metadata_tags
  }

  tags = merge(
    {
      Name        = var.name
      Environment = var.environment
    },
    var.tags
  )

  volume_tags = merge(
    {
      Name        = "${var.name}-volume"
      Environment = var.environment
    },
    var.tags
  )
}
