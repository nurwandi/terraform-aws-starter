# EKS Module

This module creates a production-ready Amazon EKS cluster with support for both Auto Mode and Managed Node Groups.

## Features

- ☸️ EKS 1.31 cluster with latest Kubernetes features
- 🤖 EKS Auto Mode support (fully managed compute, storage, networking)
- 👥 Managed Node Groups with auto-scaling
- 🔐 Cluster encryption with AWS KMS
- 📝 CloudWatch Logs integration
- 🔑 IRSA (IAM Roles for Service Accounts) support
- 🔌 Essential add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver

## Usage

```hcl
module "eks" {
  source = "./modules/eks"

  environment    = "production"
  cluster_name   = "production-eks"
  cluster_version = "1.31"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Auto Mode (fully managed) or Managed Node Groups
  auto_mode_enabled = false

  node_groups = {
    general = {
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }

  enable_cluster_encryption = true
  enabled_cluster_log_types = ["api", "audit", "authenticator"]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_addon.coredns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.kube_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_instance_profile.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_openid_connect_provider.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster_block_storage_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_compute_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_load_balancing_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_networking_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_vpc_resource_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_cni_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_container_registry_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_container_registry_pull_only](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_ebs_csi_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_worker_minimal_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_worker_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_eks_addon_version.coredns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.kube_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [tls_certificate.cluster](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_mode_enabled"></a> [auto\_mode\_enabled](#input\_auto\_mode\_enabled) | Enable EKS Auto Mode (if true, managed node groups will be skipped) | `bool` | `false` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Enable private API server endpoint | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Enable public API server endpoint | `bool` | `false` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | CIDR blocks that can access the public API server endpoint | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_cluster_log_retention_days"></a> [cluster\_log\_retention\_days](#input\_cluster\_log\_retention\_days) | CloudWatch log retention in days | `number` | `7` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS cluster name | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version | `string` | `"1.31"` | no |
| <a name="input_enable_cluster_encryption"></a> [enable\_cluster\_encryption](#input\_enable\_cluster\_encryption) | Enable envelope encryption of Kubernetes secrets | `bool` | `true` | no |
| <a name="input_enable_coredns"></a> [enable\_coredns](#input\_enable\_coredns) | Enable CoreDNS add-on | `bool` | `true` | no |
| <a name="input_enable_ebs_csi_driver"></a> [enable\_ebs\_csi\_driver](#input\_enable\_ebs\_csi\_driver) | Enable EBS CSI Driver add-on | `bool` | `true` | no |
| <a name="input_enable_kube_proxy"></a> [enable\_kube\_proxy](#input\_enable\_kube\_proxy) | Enable kube-proxy add-on | `bool` | `true` | no |
| <a name="input_enable_vpc_cni"></a> [enable\_vpc\_cni](#input\_enable\_vpc\_cni) | Enable VPC CNI add-on | `bool` | `true` | no |
| <a name="input_enabled_cluster_log_types"></a> [enabled\_cluster\_log\_types](#input\_enabled\_cluster\_log\_types) | List of control plane logging types to enable (api, audit, authenticator, controllerManager, scheduler) | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., staging, production) | `string` | n/a | yes |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Map of managed node group configurations (ignored if auto\_mode\_enabled = true) | <pre>map(object({<br>    desired_size   = number<br>    min_size       = number<br>    max_size       = number<br>    instance_types = list(string)<br>    capacity_type  = string # ON_DEMAND or SPOT<br>    disk_size      = number<br>    labels         = map(string)<br>    taints = list(object({<br>      key    = string<br>      value  = string<br>      effect = string<br>    }))<br>  }))</pre> | <pre>{<br>  "general": {<br>    "capacity_type": "ON_DEMAND",<br>    "desired_size": 2,<br>    "disk_size": 20,<br>    "instance_types": [<br>      "t3.medium"<br>    ],<br>    "labels": {<br>      "role": "general"<br>    },<br>    "max_size": 5,<br>    "min_size": 1,<br>    "taints": []<br>  }<br>}</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs for EKS cluster (private subnets recommended) | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where EKS cluster will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_addon_coredns_version"></a> [addon\_coredns\_version](#output\_addon\_coredns\_version) | Version of CoreDNS addon |
| <a name="output_addon_ebs_csi_driver_version"></a> [addon\_ebs\_csi\_driver\_version](#output\_addon\_ebs\_csi\_driver\_version) | Version of EBS CSI Driver addon |
| <a name="output_addon_kube_proxy_version"></a> [addon\_kube\_proxy\_version](#output\_addon\_kube\_proxy\_version) | Version of kube-proxy addon |
| <a name="output_addon_vpc_cni_version"></a> [addon\_vpc\_cni\_version](#output\_addon\_vpc\_cni\_version) | Version of VPC CNI addon |
| <a name="output_auto_mode_enabled"></a> [auto\_mode\_enabled](#output\_auto\_mode\_enabled) | Whether EKS Auto Mode is enabled |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | EKS cluster ARN |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data for cluster authentication |
| <a name="output_cluster_encryption_key_arn"></a> [cluster\_encryption\_key\_arn](#output\_cluster\_encryption\_key\_arn) | KMS key ARN used for cluster encryption |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | EKS cluster endpoint |
| <a name="output_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM role ARN of the EKS cluster |
| <a name="output_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | IAM role name of the EKS cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | EKS cluster ID |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | EKS cluster name |
| <a name="output_cluster_platform_version"></a> [cluster\_platform\_version](#output\_cluster\_platform\_version) | EKS cluster platform version |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group ID attached to the EKS cluster |
| <a name="output_cluster_status"></a> [cluster\_status](#output\_cluster\_status) | EKS cluster status |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | EKS cluster Kubernetes version |
| <a name="output_node_groups"></a> [node\_groups](#output\_node\_groups) | Map of node group attributes |
| <a name="output_node_iam_role_arn"></a> [node\_iam\_role\_arn](#output\_node\_iam\_role\_arn) | IAM role ARN of the EKS node groups |
| <a name="output_node_iam_role_name"></a> [node\_iam\_role\_name](#output\_node\_iam\_role\_name) | IAM role name of the EKS node groups |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | ARN of the OIDC Provider for IRSA |
| <a name="output_oidc_provider_issuer"></a> [oidc\_provider\_issuer](#output\_oidc\_provider\_issuer) | OIDC issuer URL without protocol |
| <a name="output_oidc_provider_url"></a> [oidc\_provider\_url](#output\_oidc\_provider\_url) | URL of the OIDC Provider |
<!-- END_TF_DOCS -->
