# ==============================================================================
# EFS Module
# ==============================================================================
# This module manages the Elastic File System:
#   - Creates EFS file system (standard storage, bursting throughput)
#   - Creates mount targets in private subnets
# ==============================================================================

# ------------------------------------------------------------------------------
# EFS File System
# ------------------------------------------------------------------------------

resource "aws_efs_file_system" "main" {
  creation_token = "${var.project_name}-${var.environment}-efs"

  # Performance
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Storage
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  # Encryption
  encrypted = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-efs"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# EFS Mount Targets (one per subnet/AZ)
# ------------------------------------------------------------------------------

resource "aws_efs_mount_target" "main" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [var.efs_sg_id]
}

# ------------------------------------------------------------------------------
# EFS Access Point (for application use)
# ------------------------------------------------------------------------------

resource "aws_efs_access_point" "app" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/app"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-access-point"
    Environment = var.environment
  }
}

