# EC2 Module

This module creates an EC2 instance with SSM Session Manager support, custom security groups, and encrypted storage.

## Features

- 🖥️ Amazon Linux 2023 AMI (auto-updated via SSM parameter)
- 🔐 SSM Session Manager enabled (no SSH keys required!)
- 🛡️ Custom security groups with flexible rules
- 💾 Encrypted EBS volumes (gp3)
- 🏷️ Automatic tagging
- 🔑 Optional SSH key support
- 📊 CloudWatch monitoring
- ⚡ IMDSv2 enforced

## Usage

```hcl
module "ec2" {
  source = "./modules/ec2"

  environment = "production"
  name        = "production-bastion"
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.private_subnet_ids[0]

  instance_type = "t3.small"
  enable_ssm    = true  # Enable SSM Session Manager

  # Security Group
  create_security_group = true
  security_group_rules = {
    ssh_from_vpc = {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "Allow SSH from VPC"
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  }

  # Storage
  root_volume_size      = 50
  root_volume_type      = "gp3"
  root_volume_encrypted = true
}
```

## Connecting to Instance

**Using SSM Session Manager (Recommended):**
```bash
aws ssm start-session --target i-xxxxx
```

**Using SSH (if key pair configured):**
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<private-ip>
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_ssm_parameter.ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_iam_policies"></a> [additional\_iam\_policies](#input\_additional\_iam\_policies) | Additional IAM policy ARNs to attach to instance role | `list(string)` | `[]` | no |
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | Additional security group IDs to attach | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for EC2 instance (overrides ami\_ssm\_parameter) | `string` | `null` | no |
| <a name="input_ami_ssm_parameter"></a> [ami\_ssm\_parameter](#input\_ami\_ssm\_parameter) | SSM parameter name to retrieve AMI ID (default: latest Amazon Linux 2023) | `string` | `"/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"` | no |
| <a name="input_associate_public_ip"></a> [associate\_public\_ip](#input\_associate\_public\_ip) | Associate public IP address | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Create security group for EC2 instance | `bool` | `true` | no |
| <a name="input_disable_api_termination"></a> [disable\_api\_termination](#input\_disable\_api\_termination) | Enable EC2 instance termination protection | `bool` | `false` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | Enable EBS optimization | `bool` | `true` | no |
| <a name="input_enable_ssm"></a> [enable\_ssm](#input\_enable\_ssm) | Enable SSM Session Manager access (creates IAM role with SSM policy) | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., staging, production) | `string` | n/a | yes |
| <a name="input_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#input\_iam\_instance\_profile\_arn) | Existing IAM instance profile ARN (if not using auto-created SSM role) | `string` | `""` | no |
| <a name="input_instance_initiated_shutdown_behavior"></a> [instance\_initiated\_shutdown\_behavior](#input\_instance\_initiated\_shutdown\_behavior) | Shutdown behavior (stop or terminate) | `string` | `"stop"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type | `string` | `"t3.micro"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Key pair name for SSH access (optional if using SSM Session Manager only) | `string` | `null` | no |
| <a name="input_metadata_options"></a> [metadata\_options](#input\_metadata\_options) | Metadata service options (IMDSv2) | <pre>object({<br>    http_endpoint               = string<br>    http_tokens                 = string<br>    http_put_response_hop_limit = number<br>    instance_metadata_tags      = string<br>  })</pre> | <pre>{<br>  "http_endpoint": "enabled",<br>  "http_put_response_hop_limit": 1,<br>  "http_tokens": "required",<br>  "instance_metadata_tags": "enabled"<br>}</pre> | no |
| <a name="input_monitoring"></a> [monitoring](#input\_monitoring) | Enable detailed monitoring | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the EC2 instance | `string` | n/a | yes |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | Private IP address (optional, auto-assigned if not specified) | `string` | `null` | no |
| <a name="input_root_volume_encrypted"></a> [root\_volume\_encrypted](#input\_root\_volume\_encrypted) | Encrypt root volume | `bool` | `true` | no |
| <a name="input_root_volume_iops"></a> [root\_volume\_iops](#input\_root\_volume\_iops) | IOPS for root volume (only for gp3, io1, io2) | `number` | `3000` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size of root volume in GB | `number` | `20` | no |
| <a name="input_root_volume_throughput"></a> [root\_volume\_throughput](#input\_root\_volume\_throughput) | Throughput for root volume in MB/s (only for gp3) | `number` | `125` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | Type of root volume (gp3, gp2, io1, io2) | `string` | `"gp3"` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | Map of security group rules | <pre>map(object({<br>    type        = string # ingress or egress<br>    from_port   = number<br>    to_port     = number<br>    protocol    = string<br>    cidr_blocks = list(string)<br>    description = string<br>  }))</pre> | <pre>{<br>  "egress_all": {<br>    "cidr_blocks": [<br>      "0.0.0.0/0"<br>    ],<br>    "description": "Allow all outbound",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "to_port": 0,<br>    "type": "egress"<br>  }<br>}</pre> | no |
| <a name="input_source_dest_check"></a> [source\_dest\_check](#input\_source\_dest\_check) | Enable source/destination checking (disable for NAT instances) | `bool` | `true` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for EC2 instance | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for all resources | `map(string)` | `{}` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | User data script to run on instance launch | `string` | `""` | no |
| <a name="input_user_data_replace_on_change"></a> [user\_data\_replace\_on\_change](#input\_user\_data\_replace\_on\_change) | Recreate instance when user\_data changes | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where EC2 instance will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ami_id"></a> [ami\_id](#output\_ami\_id) | AMI ID used for the instance |
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Availability zone where instance is deployed |
| <a name="output_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#output\_iam\_instance\_profile\_arn) | IAM instance profile ARN |
| <a name="output_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#output\_iam\_instance\_profile\_name) | IAM instance profile name |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | IAM role ARN (if created) |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | IAM role name (if created) |
| <a name="output_instance_arn"></a> [instance\_arn](#output\_instance\_arn) | EC2 instance ARN |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | EC2 instance ID |
| <a name="output_instance_state"></a> [instance\_state](#output\_instance\_state) | EC2 instance state |
| <a name="output_instance_type"></a> [instance\_type](#output\_instance\_type) | EC2 instance type |
| <a name="output_private_dns"></a> [private\_dns](#output\_private\_dns) | Private DNS name |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | Private IP address |
| <a name="output_public_dns"></a> [public\_dns](#output\_public\_dns) | Public DNS name (if assigned) |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | Public IP address (if assigned) |
| <a name="output_root_volume_id"></a> [root\_volume\_id](#output\_root\_volume\_id) | Root volume ID |
| <a name="output_root_volume_size"></a> [root\_volume\_size](#output\_root\_volume\_size) | Root volume size in GB |
| <a name="output_root_volume_type"></a> [root\_volume\_type](#output\_root\_volume\_type) | Root volume type |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | Security group ARN (if created) |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID (if created) |
| <a name="output_ssm_connect_command"></a> [ssm\_connect\_command](#output\_ssm\_connect\_command) | AWS CLI command to connect via SSM Session Manager |
| <a name="output_ssm_enabled"></a> [ssm\_enabled](#output\_ssm\_enabled) | Whether SSM Session Manager is enabled |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | Subnet ID where instance is deployed |
<!-- END_TF_DOCS -->
