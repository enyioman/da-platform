output "redis_cluster_id" {
  description = "ID of the Redis cluster"
  value       = var.automatic_failover_enabled ? aws_elasticache_replication_group.main[0].id : aws_elasticache_cluster.main[0].id
}

output "redis_endpoint" {
  description = "Endpoint for Redis cluster"
  value       = var.automatic_failover_enabled ? aws_elasticache_replication_group.main[0].primary_endpoint_address : aws_elasticache_cluster.main[0].cache_nodes[0].address
}

output "redis_port" {
  description = "Port for Redis cluster"
  value       = var.automatic_failover_enabled ? aws_elasticache_replication_group.main[0].port : aws_elasticache_cluster.main[0].port
}

output "redis_reader_endpoint" {
  description = "Reader endpoint for Redis replication group (if automatic failover enabled)"
  value       = var.automatic_failover_enabled ? aws_elasticache_replication_group.main[0].reader_endpoint_address : null
}

output "parameter_group_name" {
  description = "Name of the Redis parameter group"
  value       = aws_elasticache_parameter_group.main.name
}
