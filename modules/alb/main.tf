########## Security Group for ALB ##########
############################################

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for ${var.name} ALB"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name        = "${var.name}-alb-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# HTTP ingress
resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = var.enable_http_listener ? toset(var.allowed_cidr_blocks) : []

  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP inbound from ${each.value}"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# HTTPS ingress
resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = var.enable_https_listener ? toset(var.allowed_cidr_blocks) : []

  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS inbound from ${each.value}"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# Egress - allow all outbound
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

########## Application Load Balancer ##########
###############################################

resource "aws_lb" "main" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = concat([aws_security_group.alb.id], var.additional_security_group_ids)
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  idle_timeout                     = var.idle_timeout
  ip_address_type                  = var.ip_address_type

  # Security hardening
  drop_invalid_header_fields = var.drop_invalid_header_fields
  desync_mitigation_mode     = var.desync_mitigation_mode
  preserve_host_header       = var.preserve_host_header

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(
    {
      Name        = var.name
      Environment = var.environment
    },
    var.tags
  )
}

########## WAF Association ##########
#####################################

resource "aws_wafv2_web_acl_association" "main" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.waf_web_acl_arn
}

########## Target Groups ##########
###################################

resource "aws_lb_target_group" "main" {
  for_each = var.target_groups

  name                 = "${var.name}-${each.key}"
  port                 = each.value.port
  protocol             = each.value.protocol
  target_type          = each.value.target_type
  vpc_id               = var.vpc_id
  deregistration_delay = each.value.deregistration_delay

  health_check {
    enabled             = each.value.health_check.enabled
    healthy_threshold   = each.value.health_check.healthy_threshold
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    timeout             = each.value.health_check.timeout
    interval            = each.value.health_check.interval
    path                = each.value.health_check.path
    matcher             = each.value.health_check.matcher
    protocol            = each.value.health_check.protocol
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness.enabled ? [1] : []
    content {
      type            = each.value.stickiness.type
      cookie_duration = each.value.stickiness.cookie_duration
      cookie_name     = each.value.stickiness.type == "app_cookie" ? each.value.stickiness.cookie_name : null
      enabled         = true
    }
  }

  tags = merge(
    {
      Name        = "${var.name}-${each.key}"
      Environment = var.environment
    },
    var.tags
  )
}

########## HTTP Listener ##########
###################################

resource "aws_lb_listener" "http" {
  count = var.enable_http_listener ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # If redirect to HTTPS is enabled, use redirect action
  # Otherwise, forward to default target group
  dynamic "default_action" {
    for_each = var.http_redirect_to_https && var.enable_https_listener ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.http_redirect_to_https && var.enable_https_listener ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main[keys(var.target_groups)[0]].arn
    }
  }

  tags = merge(
    {
      Name        = "${var.name}-http-listener"
      Environment = var.environment
    },
    var.tags
  )
}

########## HTTPS Listener ##########
####################################

resource "aws_lb_listener" "https" {
  count = var.enable_https_listener ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[keys(var.target_groups)[0]].arn
  }

  tags = merge(
    {
      Name        = "${var.name}-https-listener"
      Environment = var.environment
    },
    var.tags
  )
}

# Additional SSL certificates for HTTPS listener
resource "aws_lb_listener_certificate" "additional" {
  for_each = var.enable_https_listener ? toset(var.additional_ssl_certificate_arns) : []

  listener_arn    = aws_lb_listener.https[0].arn
  certificate_arn = each.value
}

########## Listener Rules ##########
####################################

resource "aws_lb_listener_rule" "main" {
  for_each = var.listener_rules

  listener_arn = each.value.listener == "https" ? aws_lb_listener.https[0].arn : aws_lb_listener.http[0].arn
  priority     = each.value.priority

  dynamic "action" {
    for_each = each.value.actions
    content {
      type             = action.value.type
      target_group_arn = action.value.type == "forward" ? aws_lb_target_group.main[action.value.target_group_key].arn : null

      dynamic "redirect" {
        for_each = action.value.type == "redirect" ? [1] : []
        content {
          protocol    = action.value.redirect_protocol
          status_code = action.value.redirect_status
        }
      }

      dynamic "fixed_response" {
        for_each = action.value.type == "fixed-response" ? [1] : []
        content {
          content_type = action.value.fixed_response_content_type
          status_code  = action.value.fixed_response_status_code
          message_body = action.value.fixed_response_message
        }
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      dynamic "path_pattern" {
        for_each = condition.value.type == "path-pattern" ? [1] : []
        content {
          values = condition.value.values
        }
      }

      dynamic "host_header" {
        for_each = condition.value.type == "host-header" ? [1] : []
        content {
          values = condition.value.values
        }
      }

      dynamic "http_header" {
        for_each = condition.value.type == "http-header" ? [1] : []
        content {
          http_header_name = condition.value.values[0]
          values           = slice(condition.value.values, 1, length(condition.value.values))
        }
      }

      dynamic "query_string" {
        for_each = condition.value.type == "query-string" ? [1] : []
        content {
          key   = split("=", condition.value.values[0])[0]
          value = split("=", condition.value.values[0])[1]
        }
      }
    }
  }

  tags = merge(
    {
      Name        = "${var.name}-rule-${each.key}"
      Environment = var.environment
    },
    var.tags
  )
}
