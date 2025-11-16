# ------------------------------------------------------------------------------
# EFS Module Variables
# ------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "efs_sg_id" {
  description = "Security Group ID for EFS"
  type        = string
}

