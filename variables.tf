# Root Variables Configuration

# General Configuration
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "dals-language"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "DevOps Team"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (costs money, set to false for dev to save cost)"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for AWS services"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

# Application Configuration
variable "container_image" {
  description = "Docker image for the application"
  type        = string
  default     = "nginx:latest" # Replace with your ECR image
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

# ECS Configuration
variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

# Load Balancer Configuration
variable "enable_https" {
  description = "Enable HTTPS on ALB (requires certificate)"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for HTTPS (required if enable_https is true)"
  type        = string
  default     = ""
}

# RDS Configuration
variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.1"
}

variable "rds_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "database_username" {
  description = "Master username for database"
  type        = string
  default     = "dbadmin"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS (higher cost but better availability)"
  type        = bool
  default     = false # Set to true for production
}

variable "rds_backup_retention" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "rds_maintenance_window" {
  description = "Maintenance window for RDS"
  type        = string
  default     = "sun:03:00-sun:04:00"
}

variable "rds_backup_window" {
  description = "Backup window for RDS"
  type        = string
  default     = "02:00-03:00"
}

# ElastiCache Configuration
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 1
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_automatic_failover" {
  description = "Enable automatic failover for Redis"
  type        = bool
  default     = false # Set to true with 2+ nodes for production
}

variable "redis_maintenance_window" {
  description = "Maintenance window for Redis"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "redis_snapshot_retention" {
  description = "Number of days to retain Redis snapshots"
  type        = number
  default     = 5
}

# S3 Configuration
variable "s3_enable_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_enable_lifecycle" {
  description = "Enable lifecycle policies for S3 bucket"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "alarm_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = "fynewily@gmail.com"
}
