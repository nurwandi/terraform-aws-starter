# ALB Module

This module creates an Application Load Balancer with support for HTTP/HTTPS listeners, target groups, and advanced routing rules.

## Features

- 🌐 Internet-facing or internal ALB
- 🔒 HTTPS with ACM certificate support
- 🔄 HTTP to HTTPS redirect
- 🎯 Multiple target groups with health checks
- 🛡️ AWS WAF integration
- 📊 Access logs to S3
- 🏷️ Session stickiness support
- 🚦 Path-based and host-based routing

## Usage

```hcl
module "alb" {
  source = "./modules/alb"

  environment = "production"
  name        = "production-alb"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  internal                   = false
  enable_deletion_protection = true
  allowed_cidr_blocks        = ["0.0.0.0/0"]

  # HTTPS Configuration
  enable_https_listener   = true
  ssl_certificate_arn     = "arn:aws:acm:..."
  http_redirect_to_https  = true

  # Target Groups
  target_groups = {
    default = {
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
      health_check = {
        enabled  = true
        path     = "/"
        matcher  = "200"
      }
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
