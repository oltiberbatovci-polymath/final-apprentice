provider "aws" {
  region = var.region
}

# Provider alias for us-east-1 (required for CloudFront/WAF resources)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Data sources for account and region information
data "aws_caller_identity" "current" {}

module "s3" {
  source                      = "./modules/s3"
  frontend_bucket_name        = var.frontend_bucket_name
  alb_logs_bucket_name        = var.alb_logs_bucket_name
  cloudfront_logs_bucket_name = var.cloudfront_logs_bucket_name
  tags                        = var.tags
}

module "vpc" {
  source          = "./modules/vpc"
  name            = var.vpc_name
  cidr_block      = var.vpc_cidr_block
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  db_subnets      = var.db_subnets
  azs             = var.azs
  container_port  = var.container_port
  tags            = var.tags
}

module "rds" {
  source = "./modules/rds"

  name                  = "${var.ecs_name}-db"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.db_subnet_ids
  app_security_group_id = module.vpc.ecs_security_group_id

  # Database configuration
  database_name  = "infrastructure"
  instance_class = var.rds_instance_class
  engine_version = var.rds_engine_version

  # Storage
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  # Reliability settings
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection     = var.rds_deletion_protection

  # Monitoring
  monitoring_interval          = 60
  performance_insights_enabled = true
  alarm_actions                = [module.sns.sns_topic_arn]

  # Read replica for staging
  create_read_replica         = var.environment == "staging" ? true : false
  read_replica_instance_class = var.rds_instance_class

  tags = var.tags
}

# Standby RDS (Warm Standby for Database)
module "rds_standby" {
  source = "./modules/rds"

  name                  = "${var.ecs_name}-db-standby"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.db_subnet_ids
  app_security_group_id = module.vpc.ecs_security_group_id

  # Database configuration - same as primary
  database_name  = "infrastructure"
  instance_class = var.rds_instance_class
  engine_version = var.rds_engine_version

  # Storage - smaller for standby
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  # Reliability settings - less frequent backups for standby
  multi_az                = false # Single AZ for standby to reduce costs
  backup_retention_period = 3     # Shorter retention for standby
  deletion_protection     = var.rds_deletion_protection

  # Monitoring - basic monitoring for standby
  monitoring_interval          = 0     # No enhanced monitoring for standby
  performance_insights_enabled = false # Disabled for standby
  alarm_actions                = [module.sns.sns_topic_arn]

  # No read replica for standby
  create_read_replica         = false
  read_replica_instance_class = var.rds_instance_class

  tags = merge(var.tags, {
    Purpose = "Standby"
    Tier    = "Database"
  })
}

# ElastiCache Module (Redis)
module "elasticache" {
  source = "./modules/elasticache"

  name                  = "${var.ecs_name}-cache"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.db_subnet_ids # Use same isolated subnets as RDS
  app_security_group_id = module.vpc.ecs_security_group_id

  # Redis configuration
  engine_version = var.redis_engine_version
  node_type      = var.redis_node_type
  port           = var.redis_port

  # High availability (disabled for staging to reduce costs)
  num_cache_nodes         = var.redis_num_cache_nodes
  automatic_failover_enabled = var.redis_automatic_failover_enabled
  multi_az_enabled        = var.redis_multi_az_enabled

  # Backup and maintenance
  snapshot_retention_limit = var.redis_snapshot_retention_limit
  snapshot_window         = var.redis_snapshot_window
  maintenance_window      = var.redis_maintenance_window

  # Security
  transit_encryption_enabled = var.redis_transit_encryption_enabled
  at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled

  # Monitoring
  log_retention_days      = var.log_retention_days
  cpu_alarm_threshold     = var.redis_cpu_alarm_threshold
  memory_alarm_threshold  = var.redis_memory_alarm_threshold
  evictions_alarm_threshold = var.redis_evictions_alarm_threshold
  alarm_actions           = [module.sns.sns_topic_arn]

  tags = merge(var.tags, {
    Purpose = "Cache"
    Tier    = "Cache"
  })
}

module "alb" {
  source                     = "./modules/alb"
  name                       = var.alb_name
  security_group_ids         = [module.vpc.alb_security_group_id]
  access_logs_bucket         = module.s3.alb_logs_bucket_name
  public_subnet_ids          = module.vpc.public_subnet_ids
  enable_deletion_protection = true
  tags                       = var.tags
  vpc_id                     = module.vpc.vpc_id
  target_port                = var.target_port
  health_check_path          = var.health_check_path
}

# Standby ALB (Warm Standby)
# Use shortened name to fit within AWS 32-char limit for ALB and target group names
locals {
  # Shorten standby ALB name to fit within limits
  # Base: "final-apprentice-alb-staging" (29 chars)
  # Standby: "final-appr-alb-stg-sb" (22 chars, with "-api" = 26 chars) ✓
  standby_alb_name = "final-appr-alb-stg-sb"
}

module "alb_standby" {
  source                     = "./modules/alb"
  name                       = local.standby_alb_name
  security_group_ids         = [module.vpc.alb_security_group_id]
  access_logs_bucket         = module.s3.alb_logs_bucket_name
  public_subnet_ids          = module.vpc.public_subnet_ids
  enable_deletion_protection = true
  tags                       = var.tags
  vpc_id                     = module.vpc.vpc_id
  target_port                = var.target_port
  health_check_path          = var.health_check_path
}

module "ecs" {
  source                = "./modules/ecs"
  name                  = var.ecs_name
  tags                  = var.tags
  cpu                   = var.cpu
  memory                = var.memory
  container_definitions = local.container_definition
  desired_count         = var.desired_count
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_ids    = [module.vpc.ecs_security_group_id]
  target_group_arn      = module.alb.target_group_arn
  container_name        = var.container_name
  container_port        = var.container_port
  
  # Autoscaling configuration
  min_capacity          = var.ecs_min_capacity
  max_capacity          = var.ecs_max_capacity
  cpu_autoscale_target = var.ecs_cpu_autoscale_target
  memory_autoscale_target = var.ecs_memory_autoscale_target
}

# Standby ECS Service (Warm Standby)
module "ecs_standby" {
  source                = "./modules/ecs"
  name                  = "${var.ecs_name}-standby"
  tags                  = var.tags
  cpu                   = var.cpu
  memory                = var.memory
  container_definitions = local.container_definition_standby
  desired_count         = 1 # Minimal standby
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_ids    = [module.vpc.ecs_security_group_id]
  target_group_arn      = module.alb_standby.target_group_arn
  container_name        = var.container_name
  container_port        = var.container_port
}

# Route 53 Failover for Warm Standby
# Enables automatic DNS failover between primary and standby ALBs
module "route53_failover" {
  count = var.enable_route53_failover && var.api_dns_name != "" && var.alb_zone_id != "" ? 1 : 0

  source               = "./modules/route53"
  primary_alb_dns_name = module.alb.alb_dns_name
  standby_alb_dns_name = module.alb_standby.alb_dns_name
  alb_zone_id          = var.alb_zone_id
  route53_zone_id      = var.route53_zone_id
  api_dns_name         = var.api_dns_name
  health_check_path    = var.health_check_path
  tags                 = var.tags
}

# WAF Module
module "waf" {
  source                = "./modules/waf"
  environment           = var.environment
  alb_arn               = module.alb.alb_arn
  enable_alb_protection = true
  blacklisted_ips       = var.waf_blacklisted_ips
  rate_limit            = var.waf_rate_limit
  allowed_countries     = var.waf_allowed_countries
  tags                  = merge(var.tags, { Name = "${var.environment}-waf" })

  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}

# ACM certificate for CloudFront
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = var.frontend_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# DNS validation records in your hosted zone
resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for r in aws_route53_record.cloudfront_cert_validation : r.fqdn]
}

module "cloudfront" {
  source                  = "./modules/cloudfront"
  s3_domain_name          = module.s3.frontend_bucket_domain_name
  alb_domain_name         = module.alb.alb_dns_name
  logs_bucket_domain_name = module.s3.cloudfront_logs_bucket_domain_name
  web_acl_arn             = module.waf.cloudfront_web_acl_arn
  aliases                 = [var.frontend_domain_name]
  acm_certificate_arn     = aws_acm_certificate_validation.cloudfront.certificate_arn
  tags                    = var.tags
}

# Route53 A record pointing domain to CloudFront
resource "aws_route53_record" "frontend" {
  zone_id = var.route53_zone_id
  name    = var.frontend_domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID (same for all distributions)
    evaluate_target_health = false
  }
}

# Route53 AAAA record for IPv6 support
resource "aws_route53_record" "frontend_ipv6" {
  zone_id = var.route53_zone_id
  name    = var.frontend_domain_name
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID (same for all distributions)
    evaluate_target_health = false
  }
}

module "cloudwatch" {
  source                     = "./modules/cloudwatch"
  name                       = var.ecs_name
  log_retention_days         = var.log_retention_days
  tags                       = var.tags
  dashboard_body             = var.dashboard_body
  ecs_cpu_threshold          = var.ecs_cpu_threshold
  ecs_cluster_name           = module.ecs.cluster_name
  ecs_service_name           = module.ecs.service_name
  alb_arn_suffix             = module.alb.alb_arn_suffix
  sns_topic_arn              = module.sns.sns_topic_arn
  alb_name                   = var.alb_name
  environment                = var.environment
  cloudfront_distribution_id = var.cloudfront_distribution_id
}

# Enhanced Monitoring Module with comprehensive dashboards and alarms
module "monitoring" {
  source                     = "./modules/monitoring"
  environment                = var.environment
  tags                       = var.tags
  alb_name                   = var.alb_name
  alb_arn                    = module.alb.alb_arn
  alb_arn_suffix             = module.alb.alb_arn_suffix
  sns_topic_arn              = module.sns.sns_topic_arn
  cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
  ecs_cluster_name           = module.ecs.cluster_name
  ecs_service_name           = module.ecs.service_name
  rds_identifier             = module.rds.rds_instance_id
  redis_replication_group_id = module.elasticache.replication_group_id
  alb_latency_threshold      = 1.0
  alb_5xx_threshold          = 5
  alb_4xx_threshold          = 50
  cloudfront_cache_hit_ratio_threshold = 80
  cpu_utilization_threshold  = 80
  memory_utilization_threshold = 80
}

module "sns" {
  source          = "./modules/sns"
  name            = "${var.environment}-alerts"
  tags            = var.tags
  sns_alert_email = var.sns_alert_email
  slack_webhook   = var.sns_slack_webhook
}

module "athena" {
  source                      = "./modules/athena"
  database_name               = var.athena_database_name
  s3_bucket                   = module.s3.alb_logs_bucket_name
  workgroup_name              = var.athena_workgroup_name
  output_location             = var.athena_output_location
  environment                 = var.environment
  alb_logs_s3_location        = "s3://${module.s3.alb_logs_bucket_name}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/elasticloadbalancing/${var.region}/"
  cloudfront_logs_s3_location = "s3://${module.s3.alb_logs_bucket_name}/cloudfront-logs/"
  tags                        = var.tags
}

# S3 bucket for AWS Config
resource "aws_s3_bucket" "config_bucket" {
  bucket = "${var.environment}-aws-config-bucket-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-aws-config-bucket"
    }
  )
}

resource "aws_s3_bucket_versioning" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Security module
module "security" {
  source             = "./modules/security"
  vpc_id             = module.vpc.vpc_id
  environment        = var.environment
  config_s3_bucket   = aws_s3_bucket.config_bucket.id
  sns_topic_arn      = module.sns.sns_topic_arn # Using the existing SNS module
  log_retention_days = 90

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = "AWS Infrastructure"
    }
  )
}

# module "monitoring_alarms" {
#   source                     = "./modules/monitoring_alarms"
#   alb_name                   = var.alb_name
#   alb_arn                    = module.alb.alb_arn
#   alb_arn_suffix             = module.alb.alb_arn_suffix
#   sns_topic_arn              = module.sns.sns_topic_arn
#   cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
#   environment                = var.environment
#   tags                       = var.tags
# }

# module "cicd" {
#   source                     = "../cicd"
#   github_owner               = var.github_owner
#   github_repo                = var.github_repo
#   github_branch              = var.github_branch
#   github_token               = var.github_token
#   terraform_state_bucket     = "bardhi-ecom-terraform-state-dev"
#   terraform_state_key        = "state/terraform.tfstate"
#   ecr_repository_url         = module.ecr.repository_url
#   ecs_cluster_name           = module.ecs.cluster_name
#   ecs_service_name           = module.ecs.service_name
#   frontend_bucket_name       = module.s3.frontend_bucket_name
#   cloudfront_distribution_id = module.cloudfront.distribution_id
#   alb_name                   = var.alb_name
#   app_health_url             = "https://${module.alb.alb_dns_name}"
#   sns_topic_arn              = module.sns.sns_topic_arn
#   tags                       = var.tags
# }

module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
  tags        = var.tags
}
