# Staging Environment Configuration
# Similar to production but with smaller instance sizes

# General
project_name = "dals-language-staging"
environment  = "staging"
owner        = "Enyioman"
aws_region   = "us-east-1"

# Use 2-3 AZs for staging
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Network
vpc_cidr           = "10.1.0.0/16" # Different CIDR than dev/prod
enable_nat_gateway = true
enable_vpc_endpoints = true
enable_flow_logs   = true

# Application
container_image = "nginx:latest" # Replace with your ECR image
container_port  = 80

# ECS - Production-like but smaller
ecs_task_cpu      = 512
ecs_task_memory   = 1024
ecs_desired_count = 2

# ALB
enable_https    = false # Set to true if you have staging domain
certificate_arn = ""

# RDS - Similar to production
rds_engine_version      = "17.6"
rds_instance_class      = "db.t4g.micro"
rds_allocated_storage   = 20
database_name           = "appdb"
database_username       = "dbadmin"
rds_multi_az            = true # Multi-AZ for staging
rds_backup_retention    = 1
rds_maintenance_window  = "sun:03:00-sun:04:00"
rds_backup_window       = "02:00-03:00"

# ElastiCache - Similar to production
redis_node_type             = "cache.t3.small"
redis_num_nodes             = 1
redis_engine_version        = "7.0"
redis_automatic_failover    = true
redis_maintenance_window    = "sun:05:00-sun:06:00"
redis_snapshot_retention    = 1

# S3
s3_enable_versioning = true
s3_enable_lifecycle  = true

# Monitoring
alarm_email = "fynewily@gmail.com"

# Estimated monthly cost: ~$200-250
