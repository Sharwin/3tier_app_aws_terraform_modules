# ==============================================================================
# AWS 3-Tier Application Infrastructure
# ==============================================================================
#
# This Terraform configuration deploys a production-ready 3-tier application
# architecture on AWS, consisting of:
#
#   - Public Tier: Application Load Balancer (ALB)
#   - Application Tier: Auto Scaling Group with EC2 instances (Flask app)
#   - Data Tier: RDS MySQL database and EFS shared file system
#
# Architecture:
#   ALB (public subnets) -> EC2 ASG (private subnets) -> RDS + EFS (private)
#
# Usage:
#   terraform init
#   terraform validate
#   terraform plan
#   terraform apply
#
# ==============================================================================

# ------------------------------------------------------------------------------
# Networking Module
# ------------------------------------------------------------------------------
# Manages VPC (existing), subnets (existing), and security groups (created)

module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
}

# ------------------------------------------------------------------------------
# RDS Module
# ------------------------------------------------------------------------------
# Deploys MySQL database in private subnets

module "rds" {
  source = "./modules/rds"

  project_name      = var.project_name
  environment       = var.environment
  subnet_ids        = var.private_subnet_ids
  rds_sg_id         = module.networking.rds_sg_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class
}

# ------------------------------------------------------------------------------
# EFS Module
# ------------------------------------------------------------------------------
# Deploys shared file system in private subnets

module "efs" {
  source = "./modules/efs"

  project_name = var.project_name
  environment  = var.environment
  subnet_ids   = var.private_subnet_ids
  efs_sg_id    = module.networking.efs_sg_id
}

# ------------------------------------------------------------------------------
# EC2 App Module
# ------------------------------------------------------------------------------
# Deploys ALB, Launch Template, and Auto Scaling Group

module "ec2_app" {
  source = "./modules/ec2_app"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  private_subnet_ids   = module.networking.private_subnet_ids
  alb_sg_id            = module.networking.alb_sg_id
  app_sg_id            = module.networking.app_sg_id
  instance_type        = var.instance_type
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity

  # Data tier outputs for user_data script
  efs_fs_id   = module.efs.efs_file_system_id
  db_host     = module.rds.db_host
  db_port     = module.rds.db_port
  db_name     = module.rds.db_name
  db_user     = var.db_username
  db_password = var.db_password
}

