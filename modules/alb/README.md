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
| [aws_lb.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_listener_rule.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_wafv2_web_acl_association.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs_bucket"></a> [access\_logs\_bucket](#input\_access\_logs\_bucket) | S3 bucket name for access logs (required if enable\_access\_logs = true) | `string` | `""` | no |
| <a name="input_access_logs_prefix"></a> [access\_logs\_prefix](#input\_access\_logs\_prefix) | S3 bucket prefix for access logs | `string` | `""` | no |
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | Additional security group IDs to attach to ALB | `list(string)` | `[]` | no |
| <a name="input_additional_ssl_certificate_arns"></a> [additional\_ssl\_certificate\_arns](#input\_additional\_ssl\_certificate\_arns) | Additional ACM certificate ARNs for HTTPS listener (for multiple domains) | `list(string)` | `[]` | no |
| <a name="input_allowed_cidr_blocks"></a> [allowed\_cidr\_blocks](#input\_allowed\_cidr\_blocks) | CIDR blocks allowed to access the ALB | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_desync_mitigation_mode"></a> [desync\_mitigation\_mode](#input\_desync\_mitigation\_mode) | HTTP desync mitigation mode (defensive, strictest, monitor) | `string` | `"defensive"` | no |
| <a name="input_drop_invalid_header_fields"></a> [drop\_invalid\_header\_fields](#input\_drop\_invalid\_header\_fields) | Drop invalid HTTP headers to prevent HTTP desync attacks (recommended: true) | `bool` | `true` | no |
| <a name="input_enable_access_logs"></a> [enable\_access\_logs](#input\_enable\_access\_logs) | Enable access logs to S3 | `bool` | `false` | no |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | Enable cross-zone load balancing | `bool` | `true` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Enable deletion protection | `bool` | `true` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Enable HTTP/2 | `bool` | `true` | no |
| <a name="input_enable_http_listener"></a> [enable\_http\_listener](#input\_enable\_http\_listener) | Enable HTTP listener (port 80) | `bool` | `true` | no |
| <a name="input_enable_https_listener"></a> [enable\_https\_listener](#input\_enable\_https\_listener) | Enable HTTPS listener (port 443) | `bool` | `false` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Enable WAF Web ACL association | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., staging, production) | `string` | n/a | yes |
| <a name="input_http_redirect_to_https"></a> [http\_redirect\_to\_https](#input\_http\_redirect\_to\_https) | Redirect HTTP to HTTPS (requires HTTPS listener) | `bool` | `false` | no |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | Time in seconds that the connection is allowed to be idle (1-4000) | `number` | `60` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | Whether the ALB is internal or internet-facing | `bool` | `false` | no |
| <a name="input_ip_address_type"></a> [ip\_address\_type](#input\_ip\_address\_type) | Type of IP addresses used by the subnets (ipv4 or dualstack) | `string` | `"ipv4"` | no |
| <a name="input_listener_rules"></a> [listener\_rules](#input\_listener\_rules) | Map of listener rules for routing (path-based, host-based) | <pre>map(object({<br>    priority = number<br>    listener = string # "http" or "https"<br>    actions = list(object({<br>      type                        = string # forward, redirect, fixed-response<br>      target_group_key            = string # Key from target_groups map (for forward action)<br>      redirect_protocol           = string # HTTP or HTTPS (for redirect action)<br>      redirect_status             = string # HTTP_301 or HTTP_302 (for redirect action)<br>      fixed_response_content_type = string # text/plain, text/css, text/html, application/json (for fixed-response)<br>      fixed_response_status_code  = string # HTTP status code (for fixed-response)<br>      fixed_response_message      = string # Response body (for fixed-response)<br>    }))<br>    conditions = list(object({<br>      type   = string # path-pattern, host-header, http-header, query-string<br>      values = list(string)<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the ALB | `string` | n/a | yes |
| <a name="input_preserve_host_header"></a> [preserve\_host\_header](#input\_preserve\_host\_header) | Preserve the Host header in requests forwarded to targets | `bool` | `false` | no |
| <a name="input_ssl_certificate_arn"></a> [ssl\_certificate\_arn](#input\_ssl\_certificate\_arn) | ACM certificate ARN for HTTPS listener (required if enable\_https\_listener = true) | `string` | `""` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | SSL policy for HTTPS listener | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs for ALB (public subnets recommended for internet-facing ALB) | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for all resources | `map(string)` | `{}` | no |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | Map of target group configurations | <pre>map(object({<br>    port                 = number<br>    protocol             = string<br>    target_type          = string # instance, ip, lambda, alb<br>    deregistration_delay = number<br>    health_check = object({<br>      enabled             = bool<br>      healthy_threshold   = number<br>      unhealthy_threshold = number<br>      timeout             = number<br>      interval            = number<br>      path                = string<br>      matcher             = string<br>      protocol            = string<br>    })<br>    stickiness = object({<br>      enabled         = bool<br>      type            = string # lb_cookie or app_cookie<br>      cookie_duration = number<br>      cookie_name     = string # Required if type is app_cookie<br>    })<br>  }))</pre> | <pre>{<br>  "default": {<br>    "deregistration_delay": 300,<br>    "health_check": {<br>      "enabled": true,<br>      "healthy_threshold": 3,<br>      "interval": 30,<br>      "matcher": "200",<br>      "path": "/",<br>      "protocol": "HTTP",<br>      "timeout": 5,<br>      "unhealthy_threshold": 3<br>    },<br>    "port": 80,<br>    "protocol": "HTTP",<br>    "stickiness": {<br>      "cookie_duration": 86400,<br>      "cookie_name": "",<br>      "enabled": false,<br>      "type": "lb_cookie"<br>    },<br>    "target_type": "instance"<br>  }<br>}</pre> | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where ALB will be created | `string` | n/a | yes |
| <a name="input_waf_web_acl_arn"></a> [waf\_web\_acl\_arn](#input\_waf\_web\_acl\_arn) | WAF Web ACL ARN (required if enable\_waf = true) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | ARN of the ALB |
| <a name="output_alb_arn_suffix"></a> [alb\_arn\_suffix](#output\_alb\_arn\_suffix) | ARN suffix of the ALB (for use with CloudWatch metrics) |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | DNS name of the ALB |
| <a name="output_alb_id"></a> [alb\_id](#output\_alb\_id) | ID of the ALB |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | Zone ID of the ALB (for Route53 alias records) |
| <a name="output_http_listener_arn"></a> [http\_listener\_arn](#output\_http\_listener\_arn) | ARN of the HTTP listener |
| <a name="output_https_listener_arn"></a> [https\_listener\_arn](#output\_https\_listener\_arn) | ARN of the HTTPS listener |
| <a name="output_listener_rule_arns"></a> [listener\_rule\_arns](#output\_listener\_rule\_arns) | Map of listener rule ARNs |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | Security group ARN of the ALB |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID of the ALB |
| <a name="output_target_group_arn_suffixes"></a> [target\_group\_arn\_suffixes](#output\_target\_group\_arn\_suffixes) | Map of target group ARN suffixes (for use with CloudWatch metrics) |
| <a name="output_target_group_arns"></a> [target\_group\_arns](#output\_target\_group\_arns) | Map of target group ARNs |
| <a name="output_target_group_names"></a> [target\_group\_names](#output\_target\_group\_names) | Map of target group names |
<!-- END_TF_DOCS -->
