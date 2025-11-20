variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "blacklisted_ips" {
  description = "List of IP addresses to blacklist"
  type        = list(string)
  default     = []
}

variable "enable_alb_protection" {
  description = "Whether to enable WAF protection for ALB"
  type        = bool
  default     = true
}

variable "alb_arn" {
  description = "The ARN of the ALB to associate with the WAF"
  type        = string
  default     = ""
}

variable "rate_limit" {
  description = "The maximum number of requests allowed from a single IP address in a 5-minute period"
  type        = number
  default     = 2000
}

variable "allowed_countries" {
  description = "List of allowed country codes for geo-restriction"
  type        = list(string)
  default     = ["US", "CA", "GB", "DE"]
}
