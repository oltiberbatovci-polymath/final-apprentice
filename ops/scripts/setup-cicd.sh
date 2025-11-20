#!/bin/bash

# Setup CI/CD Pipeline Configuration
# This script helps populate the CI/CD terraform.tfvars with values from the main infrastructure

set -e

echo "=========================================="
echo "CI/CD Pipeline Setup Helper"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -d "ops/iac" ]; then
    echo "Error: Please run this script from the project root directory"
    exit 1
fi

echo "Step 1: Getting outputs from main infrastructure..."
cd ops/iac

# Check if terraform state exists
if ! terraform state list > /dev/null 2>&1; then
    echo "Error: Main infrastructure not deployed yet!"
    echo "Please run 'terraform apply' in ops/iac first"
    exit 1
fi

echo "Step 2: Extracting configuration values..."

# Get outputs
ECR_REPO=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
SNS_TOPIC=$(terraform output -raw sns_topic_arn 2>/dev/null || echo "")

cd ../..

echo ""
echo "=========================================="
echo "Configuration Values Detected:"
echo "=========================================="
echo "ECR Repository URL: $ECR_REPO"
echo "ECS Cluster Name: $ECS_CLUSTER"
echo "ECS Service Name: $ECS_SERVICE"
echo "ALB DNS Name: $ALB_DNS"
echo "CloudFront Distribution ID: $CLOUDFRONT_ID"
echo "SNS Topic ARN: $SNS_TOPIC"
echo ""

# Ask for GitHub information
echo "=========================================="
echo "GitHub Configuration"
echo "=========================================="
echo "Note: Using AWS CodeStar Connections - no GitHub token needed!"
echo ""
read -p "Enter your GitHub username: " GITHUB_OWNER
read -p "Enter your GitHub repository name [final-apprentice]: " GITHUB_REPO
GITHUB_REPO=${GITHUB_REPO:-final-apprentice}
read -p "Enter your GitHub branch [main]: " GITHUB_BRANCH
GITHUB_BRANCH=${GITHUB_BRANCH:-main}

echo ""
echo "Step 3: Updating ops/cicd/terraform.tfvars..."

# Create the terraform.tfvars file
cat > ops/cicd/terraform.tfvars <<EOF
# =====================
# GitHub Configuration
# =====================
github_owner  = "$GITHUB_OWNER"
github_repo   = "$GITHUB_REPO"
github_branch = "$GITHUB_BRANCH"

# =====================
# Terraform State Configuration
# =====================
terraform_state_bucket = "final-apprentice-staging-terraform-state"
terraform_state_key    = "state/terraform.tfstate"

# =====================
# Application Configuration
# =====================
ecr_repository_url         = "$ECR_REPO"
ecs_cluster_name           = "$ECS_CLUSTER"
ecs_service_name           = "$ECS_SERVICE"
frontend_bucket_name       = "final-apprentice-frontend-staging"
cloudfront_distribution_id = "$CLOUDFRONT_ID"
alb_name                   = "final-apprentice-alb-staging"
app_health_url             = "http://$ALB_DNS"

# =====================
# Optional: SNS notifications
# =====================
sns_topic_arn = "$SNS_TOPIC"

# =====================
# Tags
# =====================
tags = {
  Project     = "Cloud Infrastructure Deployment"
  Environment = "staging"
  ManagedBy   = "Terraform"
}
EOF

echo ""
echo "=========================================="
echo "Configuration Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Deploy the CI/CD pipeline:"
echo "   cd ops/cicd"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "2. After terraform apply, authorize the GitHub connection:"
echo "   - Go to: AWS Console → Developer Tools → Connections"
echo "   - Find the PENDING connection"
echo "   - Click 'Update pending connection'"
echo "   - Authorize with GitHub"
echo ""
echo "3. Once authorized, push to main branch to trigger pipelines!"
echo "   git push origin main"
echo ""
echo "✅ No GitHub token needed - using AWS CodeStar Connections!"
echo ""

