variable "name" {
  description = "Name prefix for resources"
  type        = string
  default = "dals-language"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs for ElastiCache"
  type        = list(string)
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes (must be >= 2 for automatic failover)"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover (requires num_cache_nodes >= 2)"
  type        = bool
  default     = false
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots"
  type        = number
  default     = 5
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
