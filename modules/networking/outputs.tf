# ------------------------------------------------------------------------------
# Networking Module Outputs
# ------------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = data.aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = var.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = var.private_subnet_ids
}

output "alb_sg_id" {
  description = "Security Group ID for ALB"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "Security Group ID for App instances"
  value       = aws_security_group.app.id
}

output "rds_sg_id" {
  description = "Security Group ID for RDS"
  value       = aws_security_group.rds.id
}

output "efs_sg_id" {
  description = "Security Group ID for EFS"
  value       = aws_security_group.efs.id
}

