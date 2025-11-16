# AWS 3-Tier Application Infrastructure with Terraform

This project deploys a production-ready 3-tier application architecture on AWS using Terraform modules.

## Architecture Overview

The infrastructure consists of three tiers:

- **Public Tier**: Application Load Balancer (ALB) in public subnets
- **Application Tier**: Auto Scaling Group with EC2 instances running Flask app in private subnets
- **Data Tier**: RDS MySQL database and EFS shared file system in private subnets

## Project Structure

```
3tier_app_aws_terraform_modules/
├── main.tf              # Root module orchestrating all components
├── providers.tf         # AWS provider and Terraform configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── terraform.tfvars     # Variable values (create this for your environment)
├── docs/
│   ├── specifications.md    # Detailed specifications
│   └── TODO.md             # Project TODO list and phases
└── modules/
    ├── networking/      # VPC, subnets, and security groups
    ├── rds/            # MySQL database
    ├── efs/            # Elastic File System
    └── ec2_app/        # ALB, Launch Template, Auto Scaling Group
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Access to AWS account
- Existing VPC and subnets (Bootcamp VPC) or permissions to create them

## Getting Started

### Phase 0 - Project Setup ✅ COMPLETED

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Validate Configuration**
   ```bash
   terraform validate
   ```

3. **Format Code**
   ```bash
   terraform fmt -recursive
   ```

### Phase 1 - Networking ✅ COMPLETED

Before proceeding to Phase 2, you'll need to:

1. Create a `terraform.tfvars` file with your environment-specific values:
   ```hcl
   vpc_id             = "vpc-xxxxxxxxx"  # Your existing VPC ID
   public_subnet_ids  = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
   private_subnet_ids = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
   db_username        = "admin"
   db_password        = "your-secure-password-here"  # Use a secure password!
   ```

2. Implement the networking module to create security groups

## Deployment

Once all phases are complete:

```bash
# Review the execution plan
terraform plan

# Apply the configuration
terraform apply

# View outputs (ALB URL, etc.)
terraform output
```

## Security Notes

- All security groups follow the principle of least privilege
- RDS is not publicly accessible
- EFS is only accessible from application instances
- ALB is the only internet-facing component (port 80)
- Database credentials are marked as sensitive

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Current Status

- ✅ Phase 0: Project skeleton and basic configuration
- ✅ Phase 1: Networking & Security (Using Existing VPC/Subnets)
- ✅ Phase 2: Data Tier (RDS & EFS)
- ✅ Phase 3: Application Tier (ALB & Auto Scaling Group)
- ⏳ Phase 4: Production-ish User Data and App Wiring
- ⏳ Phase 5: Quality of Life, Variables, and Hardening
- ⏳ Phase 6: Nice-to-Have Enhancements (Optional)

## Contributing

Follow the TODO.md file in the docs/ directory for the development roadmap.

## License

This is a learning project for DevOps training.

