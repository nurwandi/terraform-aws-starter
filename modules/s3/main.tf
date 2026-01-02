########## S3 Bucket ##########
################################

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    {
      Name        = var.bucket_name
      Environment = var.environment
    },
    var.tags
  )
}

########## S3 Bucket Versioning ##########
###########################################

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

########## S3 Bucket Encryption ##########
###########################################

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_master_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_master_key_id
    }
    bucket_key_enabled = var.kms_master_key_id != null ? true : false
  }
}

########## S3 Bucket Public Access Block ##########
####################################################

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

########## S3 Bucket Lifecycle Configuration ##########
########################################################

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.lifecycle_rules.enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id

  # Depends on versioning to be configured first
  depends_on = [aws_s3_bucket_versioning.this]

  # Smart Log Lifecycle: Transitions + Expiration + Multipart Cleanup
  rule {
    id     = "smart-log-lifecycle"
    status = "Enabled"

    # Apply to all objects or specific prefix
    filter {
      prefix = var.lifecycle_rules.filter_prefix
    }

    # Transition to Standard-IA after specified days
    transition {
      days          = var.lifecycle_rules.standard_ia_days
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier Instant Retrieval after specified days
    transition {
      days          = var.lifecycle_rules.glacier_ir_days
      storage_class = "GLACIER_IR"
    }

    # Transition to Deep Archive after specified days
    transition {
      days          = var.lifecycle_rules.deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    # Expire objects after specified days
    expiration {
      days = var.lifecycle_rules.expiration_days
    }

    # Abort incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = var.lifecycle_rules.abort_incomplete_multipart_days
    }
  }
}
