# CI/CD Pipeline Setup Guide

## Prerequisites

1. ✅ Main infrastructure deployed (ops/iac)
2. ✅ GitHub repository (this one!)
3. ✅ AWS CodeStar Connections (automated setup - no GitHub token needed!)

## Quick Setup

### Option 1: Automated Setup (Recommended)

Run the setup script from the project root:

```bash
./ops/scripts/setup-cicd.sh
```

This script will:
- Get all the required values from your deployed infrastructure
- Ask for your GitHub information
- Generate the terraform.tfvars file
- Set up the GitHub token for you

### Option 2: Manual Setup

#### Step 1: Get Infrastructure Outputs

From the project root, run:

```bash
cd ops/iac
terraform output
```

You'll need these values:
- `ecr_repository_url`
- `ecs_cluster_name`
- `ecs_service_name`
- `alb_dns_name`
- `cloudfront_distribution_id`
- `sns_topic_arn`

#### Step 2: Update terraform.tfvars

Edit `ops/cicd/terraform.tfvars` and update:

```hcl
github_owner  = "YOUR_GITHUB_USERNAME"
github_repo   = "assignment-6-group-1"  # or your fork name
github_branch = "main"

ecr_repository_url         = "FROM_TERRAFORM_OUTPUT"
ecs_cluster_name           = "FROM_TERRAFORM_OUTPUT"
ecs_service_name           = "FROM_TERRAFORM_OUTPUT"
cloudfront_distribution_id = "FROM_TERRAFORM_OUTPUT"
app_health_url             = "http://FROM_ALB_DNS_NAME"
sns_topic_arn              = "FROM_TERRAFORM_OUTPUT"
```

#### Step 3: Deploy CI/CD Pipeline

```bash
cd ops/cicd
terraform init
terraform plan
terraform apply
```

#### Step 4: Authorize GitHub Connection in AWS Console

After `terraform apply` completes, you'll see a CodeStar Connection ARN in the output. You need to authorize it:

1. Go to AWS Console → Developer Tools → Connections
2. Find your connection (status will be "PENDING")
3. Click "Update pending connection"
4. Click "Install a new app" or select your GitHub account
5. Select the repository you want to connect
6. Click "Connect"

The connection status will change to "AVAILABLE" and your pipelines will start working!

**Alternative: Use AWS CLI**
```bash
# Get the connection ARN from terraform output
CONNECTION_ARN=$(terraform output -raw codestar_connection_arn)

# Open the console URL to authorize
echo "Authorize the connection at:"
echo "https://console.aws.amazon.com/codesuite/settings/connections"
```

## What Gets Created

The pipeline will create:

1. **CodeStar Connection** - Secure connection to GitHub (auto-triggers on push!)
2. **CodePipeline** (3 pipelines):
   - Terraform pipeline (infrastructure updates)
   - Frontend pipeline (web app deployment)
   - Backend pipeline (API container deployment)
3. **CodeBuild Projects** - Build and deploy applications
4. **S3 Artifact Bucket** - Stores pipeline artifacts
5. **IAM Roles** - Permissions for CodePipeline and CodeBuild

## Pipeline Flow

```
GitHub Push → Source Stage → Terraform Stage → Build Stage → Deploy Stage
```

1. **Source**: Pulls code from your GitHub repository
2. **Terraform**: Applies infrastructure changes
3. **Build**: Builds frontend and backend applications
4. **Deploy**: Deploys to ECS and S3/CloudFront

## Triggering the Pipeline

**Automatic Triggers** 🎉

Once the CodeStar Connection is authorized, the pipelines **automatically trigger** when you push to the configured branch (default: `main`)!

Just push your changes:
```bash
git add .
git commit -m "Update application"
git push origin main
```

The pipeline will automatically start within seconds!

**Manual Trigger:**
```bash
# Trigger all pipelines
aws codepipeline start-pipeline-execution --name ecommerce-terraform-pipeline
aws codepipeline start-pipeline-execution --name ecommerce-frontend-pipeline
aws codepipeline start-pipeline-execution --name ecommerce-backend-pipeline
```

## Monitoring

View pipeline status:
- AWS Console → CodePipeline
- Or run: `aws codepipeline get-pipeline-state --name <pipeline-name>`

## Troubleshooting

### Pipeline not triggering on GitHub push
- Check CodeStar Connection status is "AVAILABLE"
- Verify repository and branch name in terraform.tfvars
- Check GitHub webhook is created (GitHub Settings → Webhooks)

### "Connection pending" error
- Go to AWS Console → Developer Tools → Connections
- Authorize the pending connection
- Follow the GitHub OAuth flow

### "Access denied to S3/ECS/etc"
- Check IAM roles have correct permissions
- Review iam.tf for required permissions

### Pipeline fails at Terraform stage
- Check buildspec-terraform.yml configuration
- Verify Terraform state bucket access
- Review CloudWatch Logs for detailed errors

## Clean Up

To destroy the CI/CD infrastructure:

```bash
cd ops/cicd
terraform destroy
```

**Note**: This only destroys the CI/CD pipeline, not your application infrastructure.

## Security Notes

- ✅ AWS CodeStar Connections - secure OAuth integration (no tokens to manage!)
- ✅ Automatic webhook management by AWS
- ✅ All S3 buckets encrypted
- ✅ IAM roles follow least-privilege principle
- ✅ No hardcoded credentials in code

## Benefits of CodeStar Connections

✅ **Auto-triggers on push** - No manual intervention needed  
✅ **No token management** - AWS handles OAuth securely  
✅ **Better security** - Uses temporary credentials  
✅ **Webhook automation** - AWS creates and manages webhooks  
✅ **Easy authorization** - One-time setup in AWS Console

