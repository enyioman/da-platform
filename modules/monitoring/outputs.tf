output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "alarm_arns" {
  description = "ARNs of CloudWatch alarms"
  value = {
    alb_unhealthy_hosts      = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.arn
    alb_high_response_time   = aws_cloudwatch_metric_alarm.alb_target_response_time.arn
    ecs_cpu_high             = aws_cloudwatch_metric_alarm.ecs_cpu_high.arn
    ecs_memory_high          = aws_cloudwatch_metric_alarm.ecs_memory_high.arn
    rds_cpu_high             = aws_cloudwatch_metric_alarm.rds_cpu_high.arn
    rds_storage_low          = aws_cloudwatch_metric_alarm.rds_storage_low.arn
    redis_cpu_high           = aws_cloudwatch_metric_alarm.redis_cpu_high.arn
    redis_memory_high        = aws_cloudwatch_metric_alarm.redis_memory_high.arn
  }
}
