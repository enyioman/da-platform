# Example Terraform Variables
# Copy this file to terraform.tfvars and customize with your values

# General Configuration
project_name = "dals-language"
environment  = "Dev"
owner        = "Enyioman"
aws_region   = "us-east-1" # Virginia, USA

# Use 2 AZs for cost savings in dev (3 AZs for production)
availability_zones = ["us-east-1a", "us-east-1b"]

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
enable_nat_gateway   = true # Set to false to save $32/month per NAT Gateway (not HA)
enable_vpc_endpoints = true # Recommended for security and cost savings
enable_flow_logs     = true # Good for troubleshooting

# Application Configuration
# Replace with your ECR image after building
container_image = "nginx:latest"
container_port  = 80

# ECS Configuration
ecs_task_cpu      = 256 # 0.25 vCPU
ecs_task_memory   = 512 # 512 MB
ecs_desired_count = 2   # 2 tasks for high availability

# Load Balancer
enable_https    = false # Set to true if you have a domain and certificate
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/dummy"    # Add ACM certificate ARN if enabling HTTPS

# RDS Configuration
rds_engine_version     = "17.6"
rds_instance_class     = "db.t4g.micro" # Smallest instance, ~$15/month
rds_allocated_storage  = 20            # 20 GB
database_name          = "appdb"
database_username      = "dbadmin"
rds_multi_az           = false # Set to true for production (~2x cost)
rds_backup_retention   = 1
rds_maintenance_window = "sun:03:00-sun:04:00"
rds_backup_window      = "02:00-03:00"

# ElastiCache Configuration
redis_node_type          = "cache.t4g.micro" # Smallest instance, ~$12/month
redis_num_nodes          = 1
redis_engine_version     = "7.0"
redis_automatic_failover = false # Requires 2+ nodes
redis_maintenance_window = "sun:05:00-sun:06:00"
redis_snapshot_retention = 1

# S3 Configuration
s3_enable_versioning = true
s3_enable_lifecycle  = true

# Monitoring
alarm_email = "fynewily@gmail.com" # You'll receive CloudWatch alarms here

# Cost Optimization Tips:
# 1. Set enable_nat_gateway = false to save $32/month per NAT (loses HA)
# 2. Use only 2 AZs instead of 3 (saves one NAT Gateway = $32/month)
# 3. Set rds_multi_az = false for dev (saves ~$15/month)
# 4. Use smaller instance types for dev
# 5. Set desired_count = 1 for dev if you don't need HA
# 6. Stop the environment outside working hours (use scripts or Lambda)
#
# Estimated monthly cost with these settings:
# - NAT Gateways (2 AZs): $64/month
# - ALB: $22/month
# - ECS Fargate (2 tasks): ~$30/month
# - RDS db.t3.micro (single AZ): ~$15/month
# - ElastiCache t3.micro: ~$12/month
# - VPC endpoints: ~$7/month
# - Data transfer and other: ~$10/month
# Total: ~$160/month
#
# To reduce further for learning:
# - Use 1 NAT Gateway (not HA): saves $32/month
# - 1 ECS task instead of 2: saves $15/month
# - This brings cost to ~$113/month
