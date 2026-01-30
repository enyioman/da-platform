# Production Environment Configuration
# Full HA setup with appropriate sizing

# General
project_name = "dals-language-prod"
environment  = "prod"
owner        = "Enyioman"
aws_region   = "us-east-1"

# Use all 3 AZs for production
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Network
vpc_cidr           = "10.2.0.0/16" # Different CIDR than dev/staging
enable_nat_gateway = true
enable_vpc_endpoints = true
enable_flow_logs   = true

# Application
container_image = "nginx:latest" # Replace with your ECR image:tag
container_port  = 80

# ECS - Production sizing
ecs_task_cpu      = 1024
ecs_task_memory   = 2048
ecs_desired_count = 3 # At least 3 for HA across AZs

# ALB
enable_https    = true  # HTTPS in production
certificate_arn = "arn:aws:acm:eu-west-2:ACCOUNT_ID:certificate/CERT_ID" # Replace

# RDS - Production configuration
rds_engine_version      = "17.6"
rds_instance_class      = "db.t3.medium" # Or larger for production load
rds_allocated_storage   = 100
database_name           = "appdb"
database_username       = "dbadmin"
rds_multi_az            = true # Always Multi-AZ in production
rds_backup_retention    = 30   # 30 days for production
rds_maintenance_window  = "sun:03:00-sun:04:00"
rds_backup_window       = "02:00-03:00"

# ElastiCache - Production configuration
redis_node_type             = "cache.t3.medium"
redis_num_nodes             = 3 # 3 nodes for HA
redis_engine_version        = "7.0"
redis_automatic_failover    = true
redis_maintenance_window    = "sun:05:00-sun:06:00"
redis_snapshot_retention    = 7

# S3
s3_enable_versioning = true
s3_enable_lifecycle  = true

# Monitoring
alarm_email = "fynewily@gmail.com"

# Estimated monthly cost: ~$400-500
# - NAT Gateways (3): $96/month
# - ALB: $22/month
# - ECS (3 tasks, larger): $90/month
# - RDS t3.medium Multi-AZ: $120/month
# - ElastiCache t3.medium (3 nodes): $108/month
# - VPC endpoints: $7/month
# - Data transfer and other: $30/month
# Total: ~$473/month
#
# Cost optimization for production:
# - Use Reserved Instances or Savings Plans (30-40% savings)
# - Right-size instances based on actual usage
# - Use Auto Scaling to scale down during off-peak
