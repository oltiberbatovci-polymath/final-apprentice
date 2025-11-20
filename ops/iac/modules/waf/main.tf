resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "${var.environment}-cloudfront-waf"
  description = "WAFv2 ACL for CloudFront"
  provider    = aws.us_east_1 # CloudFront WAF must be in us-east-1
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # OWASP Top 10 rules
  rule {
    name     = "OWASPRules"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "OWASPRulesMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate-based rule
  rule {
    name     = "RateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  # Geo-restriction - Block non-US traffic
  rule {
    name     = "GeoRestriction"
    priority = 3

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = ["US", "CA", "GB", "DE"] # Allowed countries
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoRestrictionMetric"
      sampled_requests_enabled   = true
    }
  }

  # IP Blacklist - Add known bad IPs here
  rule {
    name     = "IPBlacklist"
    priority = 4

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blacklisted_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IPBlacklistMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-cloudfront-waf-metrics"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

# IP Set for blacklisted IPs
resource "aws_wafv2_ip_set" "blacklisted_ips" {
  name               = "${var.environment}-blacklisted-ips"
  description        = "Blacklisted IPs"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blacklisted_ips
  provider           = aws.us_east_1

  tags = var.tags
}

# WAF for ALB (Regional)
resource "aws_wafv2_web_acl" "alb" {
  count       = var.enable_alb_protection ? 1 : 0
  name        = "${var.environment}-alb-waf"
  description = "WAFv2 ACL for ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Same rules as CloudFront WAF
  rule {
    name     = "OWASPRules"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "OWASPRulesMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-alb-waf-metrics"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

# Associate WAF with ALB if enabled
resource "aws_wafv2_web_acl_association" "alb" {
  count        = var.enable_alb_protection ? 1 : 0
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.alb[0].arn
}
