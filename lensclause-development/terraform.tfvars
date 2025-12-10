########## Global VPC Configuration ##########
###############################################

vpc_id             = "" # Leave empty to create new VPC, or specify existing VPC ID
public_subnet_ids  = [] # Leave empty when creating new VPC
private_subnet_ids = [] # Leave empty when creating new VPC

########## VPC Module Configuration ##########
##############################################

vpc_cidr_block       = "10.3.0.0/16"                                             # CHANGE: Lensclause VPC CIDR (avoiding 10.0 staging, 10.1 production, 10.2 internal)
availability_zones   = ["ap-southeast-3a", "ap-southeast-3b", "ap-southeast-3c"] # ap-southeast-3 (Jakarta)
public_subnet_cidrs  = ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24"]
private_subnet_cidrs = ["10.3.11.0/24", "10.3.12.0/24", "10.3.13.0/24"]
enable_dns_support   = true
enable_dns_hostnames = true
single_nat_gateway   = true # true = cost-effective, false = HA

enable_flow_logs         = false # OPTIONAL: Enable for compliance/auditing
flow_logs_destination    = "cloudwatch"
flow_logs_retention_days = 7
flow_logs_s3_bucket_arn  = "" # REQUIRED if flow_logs_destination = "s3"

enable_eic_endpoint = false # Enable secure SSH via EC2 Instance Connect Endpoint

########## EKS Configuration ##########
#######################################

cluster_name                         = "lensclause-eks" # CHANGE: Your cluster name
cluster_version                      = "1.31"
auto_mode_enabled                    = false # true = EKS Auto Mode, false = Managed Node Groups
cluster_endpoint_private_access      = true
cluster_endpoint_public_access       = true          # CHANGE: false for production security
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # CHANGE: Restrict to your IP for security
enable_cluster_encryption            = true
enabled_cluster_log_types            = [] # OPTIONAL: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cluster_log_retention_days           = 7

node_groups = {
  general = {
    desired_size   = 2
    min_size       = 1
    max_size       = 5
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND" # or "SPOT" for cost savings
    disk_size      = 20
    labels = {
      role = "general"
    }
    taints = []
  }
}

enable_vpc_cni        = true
enable_coredns        = true
enable_kube_proxy     = true
enable_ebs_csi_driver = true

########## ALB Configuration ##########
#######################################

alb_name                       = "lensclause-alb" # CHANGE: Your ALB name
alb_internal                   = false
alb_enable_deletion_protection = false         # CHANGE: true for production
alb_allowed_cidr_blocks        = ["0.0.0.0/0"] # CHANGE: Restrict for security

alb_enable_access_logs = false # OPTIONAL: Enable for production compliance
alb_access_logs_bucket = ""    # REQUIRED if alb_enable_access_logs = true
alb_access_logs_prefix = "alb-logs"

alb_enable_waf      = false # OPTIONAL: Enable for production security
alb_waf_web_acl_arn = ""    # REQUIRED if alb_enable_waf = true

alb_enable_http_listener   = true
alb_http_redirect_to_https = false # CHANGE: true if using HTTPS

alb_enable_https_listener = false # OPTIONAL: Enable if you have SSL certificate
alb_ssl_certificate_arn   = ""    # REQUIRED if alb_enable_https_listener = true
alb_ssl_policy            = "ELBSecurityPolicy-TLS13-1-2-2021-06"

alb_target_groups = {
  default = {
    port                 = 80
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 300
    health_check = {
      enabled             = true
      healthy_threshold   = 3
      unhealthy_threshold = 3
      timeout             = 5
      interval            = 30
      path                = "/"
      matcher             = "200"
      protocol            = "HTTP"
    }
    stickiness = {
      enabled         = false
      type            = "lb_cookie"
      cookie_duration = 86400
      cookie_name     = ""
    }
  }
}

alb_listener_rules = {} # OPTIONAL: Add path-based or host-based routing

########## EC2 Configuration ##########
#######################################

ec2_instances = {
  # 1. Traefik - Reverse Proxy & Load Balancer (PUBLIC SUBNET)
  traefik = {
    subnet_id             = "" # Will be set to public subnet after VPC creation
    instance_type         = "t3.small"
    key_name              = null # SSM-only
    enable_ssm            = true
    create_security_group = true
    security_group_rules = {
      http_public = {
        type        = "ingress"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Public HTTP
        description = "HTTP - Public"
      }
      https_public = {
        type        = "ingress"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Public HTTPS
        description = "HTTPS - Public"
      }
      traefik_dashboard = {
        type        = "ingress"
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # TODO: Restrict in production
        description = "Traefik Dashboard"
      }
      minio_console = {
        type        = "ingress"
        from_port   = 9001
        to_port     = 9001
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # MinIO Console TCP forwarding
        description = "MinIO Console - Public"
      }
      pgadmin_console = {
        type        = "ingress"
        from_port   = 5050
        to_port     = 5050
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # pgAdmin TCP forwarding
        description = "pgAdmin Console - Public"
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
    root_volume_size      = 20
    root_volume_type      = "gp3"
    root_volume_encrypted = true
    associate_public_ip   = true # Must be in public subnet with public IP
  }

  # 2. MinIO - Object Storage
  minio = {
    subnet_id             = "" # CHANGE AFTER VPC
    instance_type         = "t3.small"
    key_name              = null
    enable_ssm            = true
    create_security_group = true
    security_group_rules = {
      minio_api = {
        type        = "ingress"
        from_port   = 9000
        to_port     = 9000
        protocol    = "tcp"
        cidr_blocks = ["10.3.0.0/16"] # From VPC only
        description = "MinIO API"
      }
      minio_console = {
        type        = "ingress"
        from_port   = 9001
        to_port     = 9001
        protocol    = "tcp"
        cidr_blocks = ["10.3.0.0/16"] # Console from VPC only
        description = "MinIO Console"
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
    root_volume_size      = 50 # Larger for storage
    root_volume_type      = "gp3"
    root_volume_encrypted = true
    associate_public_ip   = false
  }

  # 3. PostgreSQL & pgAdmin - Databases
  postgres-mongodb = {
    subnet_id             = "" # Will be set to private subnet
    instance_type         = "t3.small"
    key_name              = null
    enable_ssm            = true
    create_security_group = true
    security_group_rules = {
      postgres = {
        type        = "ingress"
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["10.3.0.0/16"] # From VPC only
        description = "PostgreSQL"
      }
      pgadmin = {
        type        = "ingress"
        from_port   = 5050
        to_port     = 5050
        protocol    = "tcp"
        cidr_blocks = ["10.3.0.0/16"] # pgAdmin from VPC (Traefik)
        description = "pgAdmin"
      }
      mongodb = {
        type        = "ingress"
        from_port   = 27017
        to_port     = 27017
        protocol    = "tcp"
        cidr_blocks = ["10.3.0.0/16"] # From VPC only
        description = "MongoDB"
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
    root_volume_size      = 40 # Larger for databases
    root_volume_type      = "gp3"
    root_volume_encrypted = true
    associate_public_ip   = false
  }

  # 4. Flask + Gemini - Python Application
  flask-gemini = {
    subnet_id             = "" # CHANGE AFTER VPC
    instance_type         = "t3.small"
    key_name              = null
    enable_ssm            = true
    create_security_group = true
    security_group_rules = {
      flask_app = {
        type        = "ingress"
        from_port   = 5000
        to_port     = 5000
        protocol    = "tcp"
        cidr_blocks = ["10.3.0.0/16"] # From VPC only
        description = "Flask Application"
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
    root_volume_size      = 20
    root_volume_type      = "gp3"
    root_volume_encrypted = true
    associate_public_ip   = false
  }

  # 5. Application Services - Golang + Vite (Amazon Linux 2023 - OLD)
  application-services = {
    subnet_id             = "" # CHANGE AFTER VPC
    instance_type         = "t3.small"
    key_name              = null
    enable_ssm            = true
    create_security_group = true
    security_group_rules = {
      golang_api = {
        type        = "ingress"
        from_port   = 9000
        to_port     = 9000
        protocol    = "tcp"
        cidr_blocks = ["10.3.0.0/16"] # From VPC only
        description = "Backend API"
      }
      vite_dev = {
        type        = "ingress"
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["10.3.0.0/16"] # Vite dev server
        description = "Frontend"
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
    root_volume_size      = 20
    root_volume_type      = "gp3"
    root_volume_encrypted = true
    associate_public_ip   = false
  }

  # 6. Application Services Ubuntu - Golang + Vite (Ubuntu 22.04 with Podman)
  application-services-ubuntu = {
    subnet_id             = "" # Same subnet as application-services
    instance_type         = "t3.small"
    ami_id                = "ami-041bd5fb7aaf53655" # Ubuntu 22.04 LTS
    key_name              = null
    enable_ssm            = true
    create_security_group = true
    security_group_rules = {
      backend_api = {
        type        = "ingress"
        from_port   = 9000
        to_port     = 9000
        protocol    = "tcp"
        cidr_blocks = ["10.3.0.0/16"] # From VPC only
        description = "Backend API (Podman)"
      }
      frontend = {
        type        = "ingress"
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["10.3.0.0/16"] # From VPC only
        description = "Frontend (Podman)"
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
    root_volume_size      = 20
    root_volume_type      = "gp3"
    root_volume_encrypted = true
    associate_public_ip   = false
  }
}
