########## KMS Key for Cluster Encryption ##########
#####################################################

resource "aws_kms_key" "eks" {
  count = var.enable_cluster_encryption ? 1 : 0

  description             = "EKS cluster ${var.cluster_name} encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    {
      Name        = "${var.cluster_name}-eks-encryption-key"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_kms_alias" "eks" {
  count = var.enable_cluster_encryption ? 1 : 0

  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

########## IAM Role for EKS Cluster ##########
##############################################

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = merge(
    {
      Name        = "${var.cluster_name}-cluster-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

########## CloudWatch Log Group ##########
##########################################

resource "aws_cloudwatch_log_group" "cluster" {
  count = length(var.enabled_cluster_log_types) > 0 ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = merge(
    {
      Name        = "${var.cluster_name}-logs"
      Environment = var.environment
    },
    var.tags
  )
}

########## EKS Cluster ##########
#################################

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  # Must be false when Auto Mode is enabled
  bootstrap_self_managed_addons = var.auto_mode_enabled ? false : true

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  # Required for Auto Mode
  access_config {
    authentication_mode = var.auto_mode_enabled ? "API_AND_CONFIG_MAP" : "CONFIG_MAP"
  }

  dynamic "encryption_config" {
    for_each = var.enable_cluster_encryption ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  # EKS Auto Mode configuration
  # All three configs must be explicitly set when using Auto Mode
  compute_config {
    enabled       = var.auto_mode_enabled
    node_pools    = var.auto_mode_enabled ? ["general-purpose"] : []
    node_role_arn = var.auto_mode_enabled ? aws_iam_role.node[0].arn : null
  }

  storage_config {
    block_storage {
      enabled = var.auto_mode_enabled
    }
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = var.auto_mode_enabled
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_resource_controller,
    aws_cloudwatch_log_group.cluster
  ]

  tags = merge(
    {
      Name        = var.cluster_name
      Environment = var.environment
    },
    var.tags
  )
}

########## OIDC Provider (for IRSA) ##########
##############################################

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    {
      Name        = "${var.cluster_name}-oidc-provider"
      Environment = var.environment
    },
    var.tags
  )
}

########## IAM Role for Node Groups ##########
##############################################

resource "aws_iam_role" "node" {
  count = var.auto_mode_enabled || length(var.node_groups) > 0 ? 1 : 0

  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = var.auto_mode_enabled ? "ec2.amazonaws.com" : "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(
    {
      Name        = "${var.cluster_name}-node-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  count = var.auto_mode_enabled || length(var.node_groups) > 0 ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  count = var.auto_mode_enabled || length(var.node_groups) > 0 ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "node_container_registry_policy" {
  count = var.auto_mode_enabled || length(var.node_groups) > 0 ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node[0].name
}

# Additional policy for EBS CSI Driver (required for persistent volumes)
resource "aws_iam_role_policy_attachment" "node_ebs_csi_policy" {
  count = (var.auto_mode_enabled || length(var.node_groups) > 0) && var.enable_ebs_csi_driver ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.node[0].name
}

# Instance Profile for Managed Node Groups ONLY (NOT for Auto Mode)
# EKS Auto Mode creates and manages its own instance profile
resource "aws_iam_instance_profile" "node" {
  count = !var.auto_mode_enabled && length(var.node_groups) > 0 ? 1 : 0

  name = "${var.cluster_name}-node-role"
  role = aws_iam_role.node[0].name

  tags = merge(
    {
      Name        = "${var.cluster_name}-node-instance-profile"
      Environment = var.environment
    },
    var.tags
  )
}

########## Managed Node Groups (only if auto_mode = false) ##########
#####################################################################

resource "aws_eks_node_group" "main" {
  for_each = var.auto_mode_enabled ? {} : var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.node[0].arn
  subnet_ids      = var.subnet_ids
  version         = var.cluster_version

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  update_config {
    max_unavailable_percentage = 33
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_container_registry_policy
  ]

  tags = merge(
    {
      Name        = "${var.cluster_name}-${each.key}"
      Environment = var.environment
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

########## EKS Add-ons ##########
#################################

# VPC CNI
resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = data.aws_eks_addon_version.vpc_cni[0].version
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    {
      Name        = "${var.cluster_name}-vpc-cni"
      Environment = var.environment
    },
    var.tags
  )
}

data "aws_eks_addon_version" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0

  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

# CoreDNS
resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = data.aws_eks_addon_version.coredns[0].version
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    {
      Name        = "${var.cluster_name}-coredns"
      Environment = var.environment
    },
    var.tags
  )
}

data "aws_eks_addon_version" "coredns" {
  count = var.enable_coredns ? 1 : 0

  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

# kube-proxy
resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = data.aws_eks_addon_version.kube_proxy[0].version
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    {
      Name        = "${var.cluster_name}-kube-proxy"
      Environment = var.environment
    },
    var.tags
  )
}

data "aws_eks_addon_version" "kube_proxy" {
  count = var.enable_kube_proxy ? 1 : 0

  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

# EBS CSI Driver
resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = data.aws_eks_addon_version.ebs_csi_driver[0].version
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = aws_iam_role.ebs_csi_driver[0].arn

  tags = merge(
    {
      Name        = "${var.cluster_name}-ebs-csi-driver"
      Environment = var.environment
    },
    var.tags
  )
}

data "aws_eks_addon_version" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.main.version
  most_recent        = true
}

# IAM Role for EBS CSI Driver (IRSA)
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name = "${var.cluster_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.cluster.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub" : "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud" : "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = merge(
    {
      Name        = "${var.cluster_name}-ebs-csi-driver-role"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}
