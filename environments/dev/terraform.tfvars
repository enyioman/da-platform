# Development Environment Configuration

# General
project_name = "dals-language"
environment  = "Dev"
owner        = "Enyioman"
aws_region   = "us-east-1"

# Use 2 AZs for dev to save costs
availability_zones = ["us-east-1a", "us-east-1b"]

# Network
vpc_cidr           = "10.0.0.0/16"
enable_nat_gateway = true  # Could set to false to save $64/month
enable_vpc_endpoints = true
enable_flow_logs   = false # Disable in dev to save costs

# Application
container_image = "nginx:latest" # Replace with your ECR image
container_port  = 80

# ECS - Smaller sizes for dev
ecs_task_cpu      = 256
ecs_task_memory   = 512
ecs_desired_count = 1 # Just 1 task for dev

# ALB
enable_https    = false
certificate_arn = ""

# RDS - Minimal config for dev
rds_engine_version      = "17.6"
rds_instance_class      = "db.t4g.micro"
rds_allocated_storage   = 20
database_name           = "appdb"
database_username       = "dbadmin"
rds_multi_az            = false # Single AZ for dev
rds_backup_retention    = 1     # Shorter retention
rds_maintenance_window  = "sun:03:00-sun:04:00"
rds_backup_window       = "02:00-03:00"

# ElastiCache - Minimal config for dev
redis_node_type             = "cache.t4g.micro"
redis_num_nodes             = 1
redis_engine_version        = "7.0"
redis_automatic_failover    = false
redis_maintenance_window    = "sun:05:00-sun:06:00"
redis_snapshot_retention    = 1

# S3
s3_enable_versioning = false # Disable to save costs in dev
s3_enable_lifecycle  = false

# Monitoring
alarm_email = "fynewily@gmail.com"

# Estimated monthly cost: ~$80-100
# - NAT Gateways (2): $64/month
# - ALB: $22/month  
# - ECS (1 task): $15/month
# - RDS t3.micro: $15/month
# - ElastiCache t3.micro: $12/month
# Total: ~$128/month
#
# To reduce further:
# - Set enable_nat_gateway = false (saves $64, loses internet from private subnets)
# - Stop environment when not using
