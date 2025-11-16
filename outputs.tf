# ------------------------------------------------------------------------------
# Root Module Outputs
# ------------------------------------------------------------------------------

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = try(module.ec2_app.alb_dns_name, "")
}

output "alb_url" {
  description = "Full URL of the Application Load Balancer"
  value       = try("http://${module.ec2_app.alb_dns_name}", "")
}

output "rds_endpoint" {
  description = "RDS instance endpoint (non-sensitive)"
  value       = try(module.rds.db_endpoint, "")
}

output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = try(module.efs.efs_file_system_id, "")
}

output "vpc_id" {
  description = "VPC ID being used"
  value       = try(module.networking.vpc_id, "")
}

