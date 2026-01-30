# Root Main Configuration
# This file composes all modules together to create the complete infrastructure

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state configuration - uncomment after creating S3 bucket and DynamoDB table
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "terraform.tfstate"
  #   region         = "eu-west-2"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Service     = var.project_name
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# Local variables
locals {
  name_prefix = "${var.project_name}-${lower(var.environment)}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name                 = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  region               = var.aws_region
  enable_nat_gateway   = var.enable_nat_gateway
  enable_vpc_endpoints = var.enable_vpc_endpoints
  enable_flow_logs     = var.enable_flow_logs

  tags = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  name           = local.name_prefix
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port

  tags = local.common_tags
}

# Application Load Balancer Module
module "alb" {
  source = "./modules/alb"

  name               = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.alb_sg_id]

  enable_https    = var.enable_https
  certificate_arn = var.certificate_arn

  tags = local.common_tags
}

# ECS Cluster and Service Module
module "ecs" {
  source = "./modules/ecs"

  name               = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.ecs_tasks_sg_id]

  # Container configuration
  container_image = var.container_image
  container_port  = var.container_port
  cpu             = var.ecs_task_cpu
  memory          = var.ecs_task_memory
  desired_count   = var.ecs_desired_count

  # ALB configuration
  target_group_arn = module.alb.target_group_arn

  # Environment variables for the application
  environment_variables = {
    ENVIRONMENT   = var.environment
    DATABASE_HOST = module.rds.db_endpoint
    REDIS_HOST    = module.elasticache.redis_endpoint
    S3_BUCKET     = module.s3.bucket_name
  }

  # Secrets (will be stored in AWS Secrets Manager)
  secrets = {
    DATABASE_PASSWORD = module.rds.db_password_secret_arn
  }

  tags = local.common_tags
}

# RDS PostgreSQL Module
module "rds" {
  source = "./modules/rds"

  name                 = local.name_prefix
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.db_subnet_group_name
  security_group_ids   = [module.security_groups.rds_sg_id]

  # Database configuration
  engine_version    = var.rds_engine_version
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage
  database_name     = var.database_name
  master_username   = var.database_username

  # High availability
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention

  # Maintenance
  maintenance_window = var.rds_maintenance_window
  backup_window      = var.rds_backup_window

  tags = local.common_tags
}

# ElastiCache Redis Module
module "elasticache" {
  source = "./modules/elasticache"

  name               = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  subnet_group_name  = module.vpc.elasticache_subnet_group_name
  security_group_ids = [module.security_groups.redis_sg_id]

  # Redis configuration
  node_type       = var.redis_node_type
  num_cache_nodes = var.redis_num_nodes
  engine_version  = var.redis_engine_version

  # High availability
  automatic_failover_enabled = var.redis_automatic_failover

  # Maintenance
  maintenance_window       = var.redis_maintenance_window
  snapshot_retention_limit = var.redis_snapshot_retention

  tags = local.common_tags
}

# S3 Bucket for Static Assets Module
module "s3" {
  source = "./modules/s3"

  name              = local.name_prefix
  enable_versioning = var.s3_enable_versioning
  enable_lifecycle  = var.s3_enable_lifecycle

  tags = local.common_tags
}

# CloudWatch Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  name             = local.name_prefix
  alb_arn          = module.alb.alb_arn
  target_group_arn = module.alb.target_group_arn
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name
  rds_instance_id  = module.rds.db_instance_id
  redis_cluster_id = module.elasticache.redis_cluster_id

  # Alarm configuration
  alarm_email = var.alarm_email

  tags = local.common_tags
}
