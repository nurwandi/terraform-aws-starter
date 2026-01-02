# S3 Module

Production-grade AWS S3 bucket module with automated lifecycle management, versioning, and encryption.

## Features

- ✅ **Automated Lifecycle Management**
  - Smart log transitions: STANDARD → STANDARD_IA → GLACIER_IR → DEEP_ARCHIVE
  - Automatic object expiration after configurable days
  - Incomplete multipart upload cleanup (prevents cost leakage)

- ✅ **Security Best Practices**
  - Block public access by default
  - Server-side encryption (AES256 or KMS)
  - Bucket name validation (DNS-compliant)

- ✅ **Flexible Configuration**
  - Optional versioning (true/false)
  - Configurable lifecycle rules with validation
  - Custom tags support

- ✅ **Cost Optimization**
  - AWS Well-Architected Framework aligned
  - Default transition at 365 days to Deep Archive (cost-optimized)
  - 7-year retention for compliance (configurable)

## Usage

### Basic Example

```hcl
module "s3" {
  source = "../modules/s3"

  environment        = "production"
  bucket_name        = "my-app-logs-prod"
  versioning_enabled = true

  tags = {
    Project = "MyApp"
  }
}
```

### Advanced Example with Custom Lifecycle

```hcl
module "s3" {
  source = "../modules/s3"

  environment        = "production"
  bucket_name        = "my-backup-bucket"
  versioning_enabled = true
  force_destroy      = false

  # Custom lifecycle rules for backup data
  lifecycle_rules = {
    enabled                         = true
    filter_prefix                   = ""      # Apply to all objects
    standard_ia_days                = 30      # Move to IA after 30 days
    glacier_ir_days                 = 90      # Move to Glacier IR after 90 days
    deep_archive_days               = 180     # Move to Deep Archive after 180 days
    expiration_days                 = 2555    # Delete after 7 years
    abort_incomplete_multipart_days = 7       # Cleanup incomplete uploads after 7 days
  }

  # KMS encryption (optional)
  kms_master_key_id = "arn:aws:kms:ap-southeast-3:123456789012:key/xxxxx"

  tags = {
    Project     = "DataBackup"
    Compliance  = "SOX"
    CostCenter  = "Engineering"
  }
}
```

## Lifecycle Rules Explained

### Smart Log Lifecycle Transitions

The module automatically manages object lifecycle with the following storage class transitions:

| Days | Storage Class | Cost/GB/Month | Use Case |
|------|---------------|---------------|----------|
| 0-29 | STANDARD | $0.025 | Frequently accessed data |
| 30-89 | STANDARD_IA | $0.0125 | Infrequently accessed (50% cheaper) |
| 90-364 | GLACIER_IR | $0.004 | Archive with instant retrieval (84% cheaper) |
| 365+ | DEEP_ARCHIVE | $0.00099 | Long-term archive (96% cheaper) |
| 2555 | DELETE | - | Automatic cleanup after 7 years |

### Multipart Upload Cleanup

Automatically aborts incomplete multipart uploads after 7 days to prevent unnecessary storage costs.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `environment` | Environment name (e.g., staging, production) | `string` | n/a | yes |
| `bucket_name` | S3 bucket name (must be globally unique) | `string` | n/a | yes |
| `force_destroy` | Allow deletion of bucket with objects | `bool` | `false` | no |
| `versioning_enabled` | Enable versioning on S3 bucket | `bool` | `false` | no |
| `block_public_access` | Block all public access to the bucket | `bool` | `true` | no |
| `kms_master_key_id` | KMS key ID for encryption (null = AES256) | `string` | `null` | no |
| `lifecycle_rules` | Lifecycle configuration object | `object` | see below | no |
| `tags` | Additional tags for the S3 bucket | `map(string)` | `{}` | no |

### Lifecycle Rules Object

```hcl
{
  enabled                         = bool    # Enable/disable lifecycle rules
  filter_prefix                   = string  # Prefix filter ("" = all objects)
  standard_ia_days                = number  # Days to IA (min: 30)
  glacier_ir_days                 = number  # Days to Glacier IR
  deep_archive_days               = number  # Days to Deep Archive
  expiration_days                 = number  # Days to delete
  abort_incomplete_multipart_days = number  # Days to cleanup multiparts
}
```

**Default Values:**
```hcl
{
  enabled                         = true
  filter_prefix                   = ""      # All objects
  standard_ia_days                = 30
  glacier_ir_days                 = 90
  deep_archive_days               = 365     # Cost-optimized
  expiration_days                 = 2555    # 7 years
  abort_incomplete_multipart_days = 7
}
```

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | The name of the bucket |
| `bucket_arn` | The ARN of the bucket |
| `bucket_domain_name` | The bucket domain name |
| `bucket_regional_domain_name` | The bucket regional domain name |
| `bucket_region` | The AWS region this bucket resides in |
| `versioning_enabled` | Whether versioning is enabled |
| `lifecycle_rules_enabled` | Whether lifecycle rules are enabled |

## Validations

The module includes automatic validations:

1. **Bucket Name**: Must be DNS-compliant (lowercase, alphanumeric, hyphens)
2. **Lifecycle Order**: Transition days must be ascending (IA < Glacier IR < Deep Archive < Expiration)
3. **AWS Requirements**: Minimum 30 days before transitioning to Standard-IA
4. **Multipart Cleanup**: Minimum 1 day for incomplete multipart upload cleanup

## Cost Optimization Recommendations

### Application Logs
```hcl
standard_ia_days   = 30
glacier_ir_days    = 90
deep_archive_days  = 365
expiration_days    = 730   # 2 years
```

### Access Logs (ALB/CloudFront)
```hcl
standard_ia_days   = 7
glacier_ir_days    = 30
deep_archive_days  = 90
expiration_days    = 365   # 1 year
```

### Backup Data
```hcl
standard_ia_days   = 30
glacier_ir_days    = 90
deep_archive_days  = 365
expiration_days    = 2555  # 7 years
```

### VPC Flow Logs
```hcl
standard_ia_days   = 7
glacier_ir_days    = 30
deep_archive_days  = 90
expiration_days    = 180   # 6 months
```

## Apply Module

From your environment directory (e.g., `internal-awsome/` or `staging/`):

```bash
# Initialize Terraform
terraform init -backend-config=backend.tfvars

# Validate configuration
terraform validate

# Preview changes
terraform plan -target=module.s3

# Apply only S3 module
terraform apply -target=module.s3

# Apply all infrastructure
terraform apply
```

## Notes

- **Bucket Naming**: S3 bucket names must be globally unique across all AWS accounts
- **Lifecycle Propagation**: Changes may take up to 24 hours to fully propagate
- **Force Destroy**: Set to `true` only for dev/test environments (allows deletion with objects)
- **Encryption**: Uses AES256 by default, specify `kms_master_key_id` for KMS encryption
- **Versioning**: Recommended for production buckets to prevent accidental deletions

## References

- [AWS S3 Lifecycle Configuration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [AWS S3 Storage Classes](https://aws.amazon.com/s3/storage-classes/)
- [Terraform AWS Provider - S3 Bucket Lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration)
- [AWS Well-Architected Framework - Cost Optimization](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)
