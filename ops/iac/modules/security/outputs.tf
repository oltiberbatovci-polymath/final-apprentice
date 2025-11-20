output "flow_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_log.name
}

output "flow_log_role_arn" {
  description = "ARN of the IAM role for VPC Flow Logs"
  value       = aws_iam_role.vpc_flow_log.arn
}

output "config_role_arn" {
  description = "ARN of the IAM role for AWS Config"
  value       = aws_iam_role.config.arn
}

# Disabled for free tier
# output "guardduty_detector_id" {
#   description = "ID of the GuardDuty detector"
#   value       = aws_guardduty_detector.main.id
# }

# output "security_hub_arn" {
#   description = "ARN of the Security Hub"
#   value       = aws_securityhub_account.main.arn
# }