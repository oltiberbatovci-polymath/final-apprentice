output "cloudfront_web_acl_arn" {
  description = "The ARN of the CloudFront WebACL"
  value       = aws_wafv2_web_acl.cloudfront.arn
}

output "alb_web_acl_arn" {
  description = "The ARN of the ALB WebACL"
  value       = var.enable_alb_protection ? aws_wafv2_web_acl.alb[0].arn : ""
}

output "ip_set_arn" {
  description = "The ARN of the IP set for blacklisted IPs"
  value       = aws_wafv2_ip_set.blacklisted_ips.arn
}
