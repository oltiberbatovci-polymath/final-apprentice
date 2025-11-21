variable "environment" {
  type = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "alb_name" {
  description = "Name of the ALB"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the ALB"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch metrics"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  type        = string
}

variable "alb_latency_threshold" {
  description = "Threshold for ALB latency alarm (seconds)"
  type        = number
  default     = 1
}

variable "alb_5xx_threshold" {
  description = "Threshold for ALB 5xx error count alarm"
  type        = number
  default     = 5
}

variable "alb_4xx_threshold" {
  description = "Threshold for ALB 4xx error count alarm"
  type        = number
  default     = 50
}

variable "cloudfront_cache_hit_ratio_threshold" {
  description = "Threshold for CloudFront cache hit ratio alarm (%)"
  type        = number
  default     = 80
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for dashboard metrics"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name for dashboard metrics"
  type        = string
}

variable "rds_identifier" {
  description = "RDS instance identifier for dashboard metrics"
  type        = string
}

variable "redis_replication_group_id" {
  description = "ElastiCache Redis replication group ID for dashboard metrics"
  type        = string
  default     = ""
}

variable "cpu_utilization_threshold" {
  description = "CPU utilization threshold for ECS alarm (%)"
  type        = number
  default     = 80
}

variable "memory_utilization_threshold" {
  description = "Memory utilization threshold for ECS alarm (%)"
  type        = number
  default     = 80
}
