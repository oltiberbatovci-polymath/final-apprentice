# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id
  tags            = var.tags
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc-flow-logs/${var.environment}-vpc"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.flow_log_key.arn
  tags              = var.tags
}

resource "aws_kms_key" "flow_log_key" {
  description             = "KMS key for VPC Flow Logs encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json
  tags                    = var.tags
}

data "aws_iam_policy_document" "kms_key_policy" {
  # Allow root account to manage the key
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow CloudWatch Logs to use the key
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.id}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "vpc_flow_log" {
  name = "vpc-flow-log-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "vpc_flow_log" {
  role       = aws_iam_role.vpc_flow_log.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# AWS Config - Disabled for free tier (already have one recorder)
# Free tier only allows 1 configuration recorder per region
# Uncomment if you don't have an existing recorder

# resource "aws_config_configuration_recorder" "main" {
#   name     = "${var.environment}-config-recorder"
#   role_arn = aws_iam_role.config.arn

#   recording_group {
#     all_supported                 = true
#     include_global_resource_types = true
#   }
# }

# resource "aws_config_delivery_channel" "main" {
#   name           = "${var.environment}-config-delivery"
#   s3_bucket_name = var.config_s3_bucket
#   s3_key_prefix  = "config"
#   sns_topic_arn  = var.sns_topic_arn

#   snapshot_delivery_properties {
#     delivery_frequency = "Six_Hours"
#   }

#   depends_on = [aws_config_configuration_recorder.main]
# }

# resource "aws_config_configuration_recorder_status" "main" {
#   name       = aws_config_configuration_recorder.main.name
#   is_enabled = true
#   depends_on = [aws_config_delivery_channel.main]
# }

resource "aws_iam_role" "config" {
  name = "${var.environment}-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# GuardDuty - Disabled for free tier (requires subscription)
# Uncomment if you have GuardDuty enabled in your account
# resource "aws_guardduty_detector" "main" {
#   enable = true
#   finding_publishing_frequency = "SIX_HOURS"
#   tags = var.tags
# }

# Security Hub - Disabled for free tier (requires subscription)
# Uncomment if you have Security Hub enabled in your account
# resource "aws_securityhub_account" "main" {}

# resource "aws_securityhub_standards_subscription" "cis" {
#   depends_on    = [aws_securityhub_account.main]
#   standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
# }

# resource "aws_securityhub_standards_subscription" "aws_foundational" {
#   depends_on    = [aws_securityhub_account.main]
#   standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
# }

# AWS Config Rules - Disabled (requires Config Recorder)
# Uncomment if you have Config enabled
# resource "aws_config_config_rule" "required_tags" {
#   name        = "${var.environment}-required-tags"
#   description = "Ensures required tags are present on resources"

#   source {
#     owner             = "AWS"
#     source_identifier = "REQUIRED_TAGS"
#   }

#   input_parameters = jsonencode({
#     tag1Key = "Environment"
#     tag2Key = "Project"
#   })
# }

# IAM Access Analyzer
resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "${var.environment}-analyzer"
  type          = "ACCOUNT"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}