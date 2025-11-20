# =====================
# GitHub Configuration
# =====================
# Update these with your GitHub information
github_owner  = "lerdisalihi-polymaths" # Your GitHub username
github_repo   = "assignment-6-group-1"  # Your repository name
github_branch = "main"                  # Branch to build from

# Note: Using AWS CodeStar Connections - no GitHub token needed!
# After 'terraform apply', you'll need to authorize the connection in AWS Console

# =====================
# Terraform State Configuration
# =====================
terraform_state_bucket = "group1-task-bucket123123123"
terraform_state_key    = "state/terraform.tfstate"

# =====================
# Application Configuration
# =====================
# These values come from the main infrastructure outputs
# Run: cd ../iac && terraform output
# to get the actual values after infrastructure is deployed

# You'll need to update these after running terraform apply in ops/iac
ecr_repository_url         = "264765155009.dkr.ecr.us-east-1.amazonaws.com/infrastructure-backenddev"
ecs_cluster_name           = "task-api-dev123141241"
ecs_service_name           = "task-api-dev123141241-api"
frontend_bucket_name       = "group1-frontend-dev123141241"
cloudfront_distribution_id = "E3RTZMLPVURQ2D"
alb_name                   = "task-alb-dev123141241"
app_health_url             = "http://task-alb-dev123141241-1337149599.us-east-1.elb.amazonaws.com"

# =====================
# Optional: SNS notifications
# =====================
sns_topic_arn = "arn:aws:sns:us-east-1:264765155009:dev-alerts"

# =====================
# Tags
# =====================
tags = {
  Project     = "Cloud Infrastructure Deployment"
  Environment = "dev"
  ManagedBy   = "Terraform"
}

