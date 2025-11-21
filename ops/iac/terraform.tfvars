# =====================
# General
# =====================
region      = "us-east-1" # AWS region for dev
environment = "staging"       # Environment name
tags = {                  # Common resource tags
  Project     = "Final-Apprentice"
  Environment = "staging"
}


   route53_zone_id = "Z0775364HM8ZHDFQ2NG4"  
# =====================
# Networking (VPC)
# =====================
vpc_name        = "insfrastructure-vpc-staging"          # VPC name
vpc_cidr_block  = "10.1.0.0/16"                      # VPC CIDR block
public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]     # Public subnets
private_subnets = ["10.1.101.0/24", "10.1.102.0/24"] # Private subnets
db_subnets      = ["10.1.201.0/24", "10.1.202.0/24"] # Database subnets (isolated)
azs             = ["us-east-1a", "us-east-1b"]       # Availability zones

# =====================
# S3 Buckets
# =====================
frontend_bucket_name        = "final-apprentice-frontend-staging" # S3 bucket for frontend
alb_logs_bucket_name        = "final-apprentice-alb-logs-staging1" # S3 bucket for ALB logs
cloudfront_logs_bucket_name = "final-apprentice-cf-logs-staging2"  # S3 bucket for CloudFront logs

# =====================
# ECS (Backend API)
# =====================
ecs_name       = "final-apprentice-dev" # ECS cluster/service name
container_name = "api"                   # ECS container name
container_port = 5000                    # Container port (matches Dockerfile EXPOSE)
cpu            = "256"                   # Fargate CPU units (dev: 256)
memory         = "512"                   # Fargate memory (dev: 512MB)
desired_count  = 1                       # Number of ECS tasks

# ECS Autoscaling Configuration
ecs_min_capacity          = 1            # Minimum number of tasks
ecs_max_capacity          = 10           # Maximum number of tasks
ecs_cpu_autoscale_target  = 60           # Target CPU utilization (%)
ecs_memory_autoscale_target = 75        # Target memory utilization (%)
# ECS container definition JSON
# ECS container definition - Now managed by template
# See container-definition.json.tpl for the actual definition

# =====================
# Load Balancer (ALB)
# =====================
alb_name          = "final-apprentice-alb-staging" # ALB name
target_port       = 3000                    # Target group port
health_check_path = "/health"               # Health check path

# =====================
# CloudFront
# =====================
aliases     = [] # No custom domain for dev
comment     = "Development CloudFront distribution"
price_class = "PriceClass_100" # Lowest cost

# =====================
# CloudWatch
# =====================
log_retention_days = 7 # Log retention (days)
# CloudWatch dashboard JSON
dashboard_body    = <<DASHBOARD
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/ECS", "CPUUtilization", "ServiceName", "final-apprentice-staging", "ClusterName", "final-apprentice-staging"],
                    [".", "MemoryUtilization", ".", ".", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "ECS Service Metrics",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "app/final-apprentice-staging/1aff461ee94a079c"],
                    [".", "RequestCount", ".", "."],
                    [".", "HTTPCode_Target_5XX_Count", ".", "."],
                    [".", "HTTPCode_Target_2XX_Count", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "ALB Performance Metrics",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "final-apprentice-staging-db"],
                    [".", "DatabaseConnections", ".", "."],
                    [".", "FreeStorageSpace", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "RDS Database Metrics",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "Requests", "DistributionId", "E1CBEUFNDAKCIO"],
                    [".", "BytesDownloaded", ".", "."],
                    [".", "CacheHitRate", ".", "."],
                    [".", "4xxErrorRate", ".", "."],
                    [".", "5xxErrorRate", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "CloudFront CDN Metrics",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 12,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["ECommerce/API", "ResponseTime"],
                    [".", "RequestCount"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "Custom API Metrics",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 8,
            "y": 12,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/WAFV2", "AllowedRequests", "WebACL", "cloudfront-waf", "Rule", "ALL"],
                    [".", "BlockedRequests", ".", ".", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "WAF Security Metrics",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 16,
            "y": 12,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/ECS", "RunningTaskCount", "ServiceName", "final-apprentice-staging", "ClusterName", "final-apprentice-staging"],
                    [".", "PendingTaskCount", ".", ".", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "ECS Task Counts",
                "period": 300,
                "stat": "Average"
            }
        }
    ]
}
DASHBOARD
ecs_cpu_threshold = 80 # CPU alarm threshold (%)
# =====================
# Route53 Failover (Warm Standby)
# =====================
enable_route53_failover = true              # Enable Route53 failover routing
api_dns_name            = "api.olti.devops.konitron.com" # API DNS name (subdomain of your domain)
alb_zone_id             = "Z35SXDOTRQ7X7K"  # ALB zone ID for us-east-1 (constant)
# route53_zone_id is already set above (line 12)

# =====================
# Athena (Log Analysis)
# =====================
athena_database_name   = "access_logs_staging123141241"    # Athena DB name
athena_workgroup_name  = "logs_workgroup_staging123141241" # Athena workgroup
athena_output_location = "s3://athena-results-staging/"    # Athena output S3 bucket URI (ensure this bucket exists)

# =====================
# WAF and Reliability
# =====================
waf_enabled  = true # Enable WAF for staging
warm_standby = true # Enable warm standby
# =====================
# RDS Database Configuration
# =====================
rds_instance_class          = "db.t3.micro" # Small instance for dev
rds_engine_version          = "15.10"       # PostgreSQL version (latest 15.x available in AWS RDS)
rds_allocated_storage       = 20            # 20GB initial storage
rds_max_allocated_storage   = 100           # Auto-scale up to 100GB
rds_multi_az                = true          # Multi-AZ for high availability (production-ready)
rds_backup_retention_period = 7             # 7 days backup retention
rds_deletion_protection     = false         # Allow deletion in dev

# =====================
# ElastiCache (Redis)
# =====================
redis_engine_version            = "7.0"              # Redis version
redis_node_type                 = "cache.t3.micro"  # Small instance for dev
redis_port                      = 6379               # Standard Redis port
redis_num_cache_nodes           = 2                 # 2 nodes required for automatic failover (production-ready)
redis_automatic_failover_enabled = true             # Enable automatic failover for high availability
redis_multi_az_enabled          = true              # Multi-AZ for high availability (production-ready)
redis_snapshot_retention_limit  = 7                 # 7 days snapshot retention (production-ready)
redis_snapshot_window            = "03:00-05:00"     # Snapshot window (UTC)
redis_maintenance_window         = "sun:05:00-sun:07:00" # Maintenance window (UTC)
redis_transit_encryption_enabled = true              # Enable encryption in transit
redis_at_rest_encryption_enabled = true              # Enable encryption at rest
redis_cpu_alarm_threshold        = 80                 # CPU alarm threshold (%)
redis_memory_alarm_threshold    = 80                 # Memory alarm threshold (%)
redis_evictions_alarm_threshold = 100                # Evictions alarm threshold