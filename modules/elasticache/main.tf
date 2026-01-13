# ElastiCache Redis Module
# Creates Redis cluster for caching

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Parameter Group for Redis
resource "aws_elasticache_parameter_group" "main" {
  name   = "${var.name}-redis-params"
  family = "redis${split(".", var.engine_version)[0]}"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = var.tags
}

# ElastiCache Subnet Group (created in VPC module, just referencing here)
# The subnet group is passed in via variable

# ElastiCache Replication Group (for Redis with automatic failover)
resource "aws_elasticache_replication_group" "main" {
  count = var.automatic_failover_enabled ? 1 : 0

  replication_group_id       = "${var.name}-redis"
  description                = "Redis cluster for ${var.name}"
  engine                     = "redis"
  engine_version             = var.engine_version
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_nodes
  parameter_group_name       = aws_elasticache_parameter_group.main.name
  port                       = 6379
  subnet_group_name          = var.subnet_group_name
  security_group_ids         = var.security_group_ids

  # High Availability
  automatic_failover_enabled = true
  multi_az_enabled          = true

  # Backup and Maintenance
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window         = "03:00-05:00"
  maintenance_window      = var.maintenance_window

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false # Set to true with auth token for production

  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-redis"
    }
  )
}

# ElastiCache Cluster (for single-node Redis without automatic failover)
resource "aws_elasticache_cluster" "main" {
  count = var.automatic_failover_enabled ? 0 : 1

  cluster_id           = "${var.name}-redis"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.main.name
  port                 = 6379
  subnet_group_name    = var.subnet_group_name
  security_group_ids   = var.security_group_ids

  # Backup
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window         = "03:00-05:00"
  maintenance_window      = var.maintenance_window

  # Logging - note: log delivery not available for cluster mode
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-redis"
    }
  )
}

# CloudWatch Log Groups for Redis
resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${var.name}-redis/slow-log"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name              = "/aws/elasticache/${var.name}-redis/engine-log"
  retention_in_days = 7

  tags = var.tags
}
