# ==============================================================================
# RDS Module
# ==============================================================================
# This module manages the MySQL RDS database:
#   - Creates DB subnet group in private subnets
#   - Deploys MySQL instance (db.t2.micro, single-AZ)
# ==============================================================================

# ------------------------------------------------------------------------------
# DB Subnet Group
# ------------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.project_name}-${var.environment}-"
  description = "Database subnet group for ${var.project_name}"
  subnet_ids  = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------
# RDS MySQL Instance
# ------------------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier_prefix = "${var.project_name}-${var.environment}-"

  # Engine
  engine         = "mysql"
  engine_version = "8.0"

  # Instance
  instance_class        = var.db_instance_class
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false

  # High Availability (disabled for cost savings)
  multi_az = false

  # Backup
  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  skip_final_snapshot       = true
  final_snapshot_identifier = null

  # Performance
  performance_insights_enabled = false

  # Monitoring (disabled to match specs - no CloudWatch)
  enabled_cloudwatch_logs_exports = []

  # Parameter group
  parameter_group_name = "default.mysql8.0"

  # Deletion protection
  deletion_protection = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-mysql"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }
}

