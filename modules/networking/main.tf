# ==============================================================================
# Networking Module
# ==============================================================================
# This module manages networking resources:
#   - Uses existing VPC and subnets (Bootcamp VPC)
#   - Creates security groups for ALB, App, RDS, and EFS tiers
# ==============================================================================

# ------------------------------------------------------------------------------
# Data Sources - Reference Existing VPC and Subnets
# ------------------------------------------------------------------------------

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnet" "public" {
  count = length(var.public_subnet_ids)
  id    = var.public_subnet_ids[count.index]
}

data "aws_subnet" "private" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

# ------------------------------------------------------------------------------
# Security Group - Application Load Balancer (ALB)
# ------------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Tier        = "public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Ingress - Allow HTTP from internet
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic from internet"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "alb-http-ingress"
  }
}

# ALB Egress - Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "alb-all-egress"
  }
}

# ------------------------------------------------------------------------------
# Security Group - Application (EC2 Instances)
# ------------------------------------------------------------------------------

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-${var.environment}-app-"
  description = "Security group for application EC2 instances"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-sg"
    Environment = var.environment
    Tier        = "application"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# App Ingress - Allow traffic on port 5000 from ALB only
resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id = aws_security_group.app.id
  description       = "Allow traffic from ALB on port 5000"

  from_port                    = 5000
  to_port                      = 5000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name = "app-from-alb-ingress"
  }
}

# App Egress - Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "app-all-egress"
  }
}

# ------------------------------------------------------------------------------
# Security Group - RDS Database
# ------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  description = "Security group for RDS MySQL database"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
    Tier        = "data"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Ingress - Allow MySQL traffic from App instances only
resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow MySQL traffic from application instances"

  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id

  tags = {
    Name = "rds-from-app-ingress"
  }
}

# RDS Egress - Allow all outbound traffic (for updates/patches)
resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "rds-all-egress"
  }
}

# ------------------------------------------------------------------------------
# Security Group - EFS (Elastic File System)
# ------------------------------------------------------------------------------

resource "aws_security_group" "efs" {
  name_prefix = "${var.project_name}-${var.environment}-efs-"
  description = "Security group for EFS file system"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-efs-sg"
    Environment = var.environment
    Tier        = "data"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EFS Ingress - Allow NFS traffic from App instances only
resource "aws_vpc_security_group_ingress_rule" "efs_from_app" {
  security_group_id = aws_security_group.efs.id
  description       = "Allow NFS traffic from application instances"

  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id

  tags = {
    Name = "efs-from-app-ingress"
  }
}

# EFS Egress - Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "efs_all" {
  security_group_id = aws_security_group.efs.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "efs-all-egress"
  }
}

