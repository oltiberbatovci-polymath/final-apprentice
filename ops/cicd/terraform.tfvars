# =====================
# GitHub Configuration
# =====================
# Update these with your GitHub information
github_owner  = "oltiberbatovci-polymath" # Your GitHub username
github_repo   = "final-apprentice"  # Your repository name
github_branch = "main"                  # Branch to build from

# Note: Using AWS CodeStar Connections - no GitHub token needed!
# After 'terraform apply', you'll need to authorize the connection in AWS Console

# =====================
# Terraform State Configuration
# =====================
terraform_state_bucket = "final-apprentice-staging-terraform-state"
terraform_state_key    = "state/terraform.tfstate"

# =====================
# Application Configuration
# =====================
# These values come from the main infrastructure outputs
# Run: cd ../iac && terraform output
# to get the actual values after infrastructure is deployed

# You'll need to update these after running terraform apply in ops/iac
ecr_repository_url         = "264765155009.dkr.ecr.us-east-1.amazonaws.com/infrastructure-backenddev"
ecs_cluster_name           = "final-apprentice-staging"
ecs_service_name           = "final-apprentice-staging-api"
frontend_bucket_name       = "final-apprentice-frontend-staging"
cloudfront_distribution_id = "ET562LRD5JTSK"
alb_name                   = "final-apprentice-alb-staging"
app_health_url             = "http://final-apprentice-alb-staging-1337149599.us-east-1.elb.amazonaws.com"

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

