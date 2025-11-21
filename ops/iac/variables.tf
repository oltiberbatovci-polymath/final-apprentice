# Optional: CloudFront aliases
variable "aliases" {
  description = "CloudFront distribution aliases"
  type        = list(string)
  default     = []
}

# Required: CloudFront distribution ID for CloudWatch
variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for metrics"
  type        = string
  default     = "dev-cloudfront-dist-id"
}

  variable "frontend_domain_name" {
    description = "Custom domain for the frontend"
    type        = string
    default     = "olti.devops.konitron.com"
  }

# Required: Environment name for CloudWatch

# Required: ALB name for CloudWatch
# Optional: CloudFront comment
variable "comment" {
  description = "Comment for CloudFront distribution"
  type        = string
  default     = "Development CloudFront distribution"
}

# Optional: CloudFront price class
variable "price_class" {
  description = "Price class for CloudFront distribution"
  type        = string
  default     = "PriceClass_100"
}
# Optional: Enable warm standby (default false)
variable "warm_standby" {
  description = "Enable warm standby ALB/ECS"
  type        = bool
  default     = false
}

variable "enable_route53_failover" {
  description = "Enable Route53 failover routing between primary and standby ALBs"
  type        = bool
  default     = false
}

# Optional: Enable WAF (default false)
# WAF Configuration
variable "waf_enabled" {
  description = "Enable WAF protection"
  type        = bool
  default     = true
}

variable "waf_blacklisted_ips" {
  description = "List of IP addresses to blacklist in WAF"
  type        = list(string)
  default     = []
}

variable "waf_rate_limit" {
  description = "The maximum number of requests allowed from a single IP address in a 5-minute period"
  type        = number
  default     = 2000
}

variable "waf_allowed_countries" {
  description = "List of allowed country codes for WAF geo-restriction"
  type        = list(string)
  default     = ["US", "CA", "GB", "DE"]
}

# Required: SNS alert email
variable "sns_alert_email" {
  description = "Email address for SNS alerts"
  type        = string
  default     = "dev-alerts@example.com"
}
# CloudWatch dashboard and alarm variables
variable "dashboard_body" {
  description = "JSON body for CloudWatch dashboard"
  type        = string
  default     = "{}"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
  default     = "dev-placeholder"
}

variable "ecs_cpu_threshold" {
  description = "CPU threshold for ECS CloudWatch alarm"
  type        = number
  default     = 80
}
# App secret for Secrets Manager
variable "app_secret_string" {
  description = "Secret string for application (example)"
  type        = string
  default     = "dev-placeholder"
}
variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# VPC
variable "vpc_name" {
  description = "Name prefix for VPC"
  type        = string
}
variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
}
variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}
variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}
variable "db_subnets" {
  description = "List of database subnet CIDRs"
  type        = list(string)
}
variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

# S3
variable "frontend_bucket_name" {
  description = "Name for frontend S3 bucket"
  type        = string
}
variable "alb_logs_bucket_name" {
  description = "Name for ALB logs S3 bucket"
  type        = string
}
variable "cloudfront_logs_bucket_name" {
  description = "Name for CloudFront logs S3 bucket"
  type        = string
}

# ALB
variable "alb_name" {
  description = "Name prefix for ALB"
  type        = string
}
variable "target_port" {
  description = "Target group port"
  type        = number
}
variable "health_check_path" {
  description = "Health check path"
  type        = string
}

# Route 53 and ALB DNS variables for failover
variable "route53_zone_id" {
  description = "Route 53 Hosted Zone ID for API DNS name"
  type        = string
  default     = ""
}

variable "api_dns_name" {
  description = "DNS name for the API (e.g., api.example.com)"
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "ALB DNS zone ID (from AWS documentation for your region)"
  type        = string
  default     = ""
}

# ECS
variable "ecs_name" {
  description = "Name prefix for ECS"
  type        = string
}
variable "container_name" {
  description = "Container name"
  type        = string
}
variable "container_port" {
  description = "Container port"
  type        = number
}
variable "cpu" {
  description = "CPU units"
  type        = string
}
variable "memory" {
  description = "Memory (MB)"
  type        = string
}
variable "desired_count" {
  description = "Number of ECS tasks"
  type        = number
}

# ECS Autoscaling
variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks for autoscaling"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks for autoscaling"
  type        = number
  default     = 10
}

variable "ecs_cpu_autoscale_target" {
  description = "Target CPU utilization for ECS autoscaling (percent)"
  type        = number
  default     = 60
}

variable "ecs_memory_autoscale_target" {
  description = "Target memory utilization for ECS autoscaling (percent)"
  type        = number
  default     = 75
}

# CloudFront

# CloudWatch
variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
}

# SNS
variable "sns_slack_webhook" {
  description = "SNS Slack webhook URL"
  type        = string
  default     = ""
}

# Athena
variable "athena_database_name" {
  description = "Athena database name"
  type        = string
}
variable "athena_workgroup_name" {
  description = "Athena workgroup name"
  type        = string
}
variable "athena_output_location" {
  description = "Athena query output S3 location"
  type        = string
}

# CI/CD Variables
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch to build from"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub OAuth token"
  type        = string
  default     = ""
  sensitive   = true
}

# =====================
# RDS Database Variables
# =====================

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.10"
}

variable "rds_allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling in GB"
  type        = number
  default     = 100
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = true
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

# =====================
# ElastiCache (Redis) Variables
# =====================

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes (1 for non-cluster mode, 2+ for cluster mode with replication)"
  type        = number
  default     = 1
}

variable "redis_automatic_failover_enabled" {
  description = "Enable automatic failover (requires num_cache_nodes >= 2)"
  type        = bool
  default     = false
}

variable "redis_multi_az_enabled" {
  description = "Enable Multi-AZ for high availability"
  type        = bool
  default     = false
}

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain snapshots"
  type        = number
  default     = 1
}

variable "redis_snapshot_window" {
  description = "Daily time range for snapshots (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "redis_maintenance_window" {
  description = "Weekly maintenance window (UTC)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "redis_transit_encryption_enabled" {
  description = "Enable encryption in transit"
  type        = bool
  default     = true
}

variable "redis_at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "redis_cpu_alarm_threshold" {
  description = "CPU utilization alarm threshold (%)"
  type        = number
  default     = 80
}

variable "redis_memory_alarm_threshold" {
  description = "Memory utilization alarm threshold (%)"
  type        = number
  default     = 80
}

variable "redis_evictions_alarm_threshold" {
  description = "Evictions alarm threshold (count)"
  type        = number
  default     = 100
}
