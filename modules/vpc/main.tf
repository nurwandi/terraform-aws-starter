########## Locals ##########
#############################
locals {
  # Extract AZ suffix (a, b, c) from availability zone names
  # Example: "ap-southeast-3a" -> "a", "us-east-1b" -> "b"
  az_suffixes = [for az in var.availability_zones : substr(az, -1, 1)]
}

########## VPC ##########
#########################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    {
      Name        = "${var.environment}-vpc"
      Environment = var.environment
    },
    var.tags
  )
}

########## Internet Gateway ##########
######################################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.environment}-igw"
      Environment = var.environment
    },
    var.tags
  )
}

########## Public Subnets ##########
####################################
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "${var.environment}-public-subnet-${local.az_suffixes[count.index]}"
      Environment = var.environment
      Type        = "public"
    },
    var.tags
  )
}

########## Private Subnets ##########
#####################################
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name        = "${var.environment}-private-subnet-${local.az_suffixes[count.index]}"
      Environment = var.environment
      Type        = "private"
    },
    var.tags
  )
}

########## Elastic IPs for NAT ##########
#########################################
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  domain = "vpc"

  tags = merge(
    {
      Name        = var.single_nat_gateway ? "${var.environment}-nat-eip" : "${var.environment}-nat-eip-${local.az_suffixes[count.index]}"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

########## NAT Gateways ##########
##################################
resource "aws_nat_gateway" "main" {
  count         = var.single_nat_gateway ? 1 : length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name        = var.single_nat_gateway ? "${var.environment}-nat" : "${var.environment}-nat-${local.az_suffixes[count.index]}"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

########## Public Route Table ##########
########################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.environment}-public-rt"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

########## Private Route Tables ##########
##########################################
resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = var.single_nat_gateway ? "${var.environment}-private-rt" : "${var.environment}-private-rt-${local.az_suffixes[count.index]}"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_route" "private_nat" {
  count                  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

########## Default Security Group ##########
############################################
resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group for ${var.environment} VPC"
  vpc_id      = aws_vpc.main.id

  # Allow inbound traffic from within VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow all traffic from within VPC"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    {
      Name        = "${var.environment}-default-sg"
      Environment = var.environment
    },
    var.tags
  )
}

########## VPC Flow Logs ##########
###################################
resource "aws_flow_log" "main" {
  count                = var.enable_flow_logs ? 1 : 0
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  iam_role_arn         = var.flow_logs_destination == "cloudwatch" ? aws_iam_role.flow_logs[0].arn : null
  log_destination_type = var.flow_logs_destination
  log_destination      = var.flow_logs_destination == "cloudwatch" ? aws_cloudwatch_log_group.flow_logs[0].arn : var.flow_logs_s3_bucket_arn

  tags = merge(
    {
      Name        = "${var.environment}-vpc-flow-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# CloudWatch Log Group for Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs && var.flow_logs_destination == "cloudwatch" ? 1 : 0
  name              = "/aws/vpc/${var.environment}-flow-logs"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(
    {
      Name        = "${var.environment}-vpc-flow-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Role for Flow Logs to CloudWatch
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination == "cloudwatch" ? 1 : 0
  name  = "${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.environment}-vpc-flow-logs-role"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Policy for Flow Logs
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination == "cloudwatch" ? 1 : 0
  name  = "${var.environment}-vpc-flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

########## VPC Endpoints ##########
###################################

# S3 Gateway Endpoint (free, no data processing charges)
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = aws_route_table.private[*].id

  tags = merge(
    {
      Name        = "${var.environment}-s3-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

# DynamoDB Gateway Endpoint (free, no data processing charges)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${var.region}.dynamodb"
  route_table_ids = aws_route_table.private[*].id

  tags = merge(
    {
      Name        = "${var.environment}-dynamodb-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}
