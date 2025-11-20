# CI/CD Pipeline Quick Start

## What's Been Set Up

Your CI/CD pipelines now use **AWS CodeStar Connections** to automatically trigger when you push to GitHub! 🎉

### Key Features:
- ✅ **Auto-triggers on git push** - No manual pipeline starts needed
- ✅ **No GitHub tokens to manage** - AWS handles OAuth securely
- ✅ **Three separate pipelines**:
  - Infrastructure (Terraform)
  - Frontend (Web App)
  - Backend (API)

## Quick Start (3 Steps)

### Step 1: Update Configuration

Edit `ops/cicd/terraform.tfvars`:
```hcl
github_owner  = "YOUR_GITHUB_USERNAME"  # ← Change this
github_repo   = "final-apprentice"  # ← Verify this matches your repo
github_branch = "main"
```

Get the infrastructure values:
```bash
cd ops/iac
terraform output
```

Then update `ops/cicd/terraform.tfvars` with those values.

**OR** Use the automated setup script:
```bash
./ops/scripts/setup-cicd.sh
```

### Step 2: Deploy Pipelines

```bash
cd ops/cicd
terraform init
terraform plan
terraform apply
```

### Step 3: Authorize GitHub Connection

After `terraform apply`, you'll see:
```
codestar_connection_arn = "arn:aws:codestar-connections:..."
codestar_connection_status = "PENDING"
```

**To authorize:**

1. Open AWS Console → [Developer Tools → Connections](https://console.aws.amazon.com/codesuite/settings/connections)
2. Find your connection (status: PENDING)
3. Click "Update pending connection"
4. Click "Connect" and authorize with GitHub
5. Select your repository

Status will change to "AVAILABLE" ✅

## That's It!

Now whenever you push to the `main` branch:
```bash
git add .
git commit -m "Update application"
git push origin main
```

Your pipelines will **automatically trigger** within seconds! 🚀

## Monitor Your Pipelines

**AWS Console:**
- [CodePipeline Dashboard](https://console.aws.amazon.com/codesuite/codepipeline/pipelines)

**AWS CLI:**
```bash
# List all pipelines
aws codepipeline list-pipelines

# Check specific pipeline
aws codepipeline get-pipeline-state --name ecommerce-terraform-pipeline
aws codepipeline get-pipeline-state --name ecommerce-frontend-pipeline
aws codepipeline get-pipeline-state --name ecommerce-backend-pipeline
```

## Pipeline Details

### 1. Terraform Pipeline
- **Triggers on:** Push to main branch
- **Actions:** 
  - Source: Pull code from GitHub
  - Plan: Run `terraform plan`
  - Apply: Run `terraform apply`
- **Updates:** Infrastructure changes

### 2. Frontend Pipeline
- **Triggers on:** Push to main branch
- **Actions:**
  - Source: Pull code from GitHub
  - Build: Build frontend app
  - Deploy: Upload to S3 + invalidate CloudFront
- **Buildspec:** `packages/web/buildspec-frontend.yml`

### 3. Backend Pipeline
- **Triggers on:** Push to main branch
- **Actions:**
  - Source: Pull code from GitHub
  - Build: Build Docker image
  - Deploy: Push to ECR + Update ECS service
- **Buildspec:** `packages/api/buildspec-backend.yml`

## Troubleshooting

### Connection stays PENDING
→ You need to authorize it in AWS Console (see Step 3 above)

### Pipeline not triggering on push
→ Check connection status is "AVAILABLE"  
→ Verify branch name matches in terraform.tfvars  
→ Check GitHub webhook exists (Settings → Webhooks)

### Build fails
→ Check CodeBuild logs in AWS Console  
→ Verify buildspec files exist  
→ Check IAM permissions

### Want to trigger manually?
```bash
aws codepipeline start-pipeline-execution \
  --name ecommerce-terraform-pipeline
```

## What Changed from Old Setup

**Before (OAuth Token):**
- ❌ Manual GitHub token creation
- ❌ Token storage in environment variables
- ❌ Token rotation when expired
- ❌ Manual webhook setup

**Now (CodeStar Connections):**
- ✅ One-time OAuth authorization
- ✅ AWS manages credentials securely
- ✅ Automatic token refresh
- ✅ Automatic webhook management

## Need More Help?

See detailed documentation:
- `ops/cicd/SETUP.md` - Full setup guide
- `ops/cicd/README.md` - Architecture details

## Clean Up

To remove the CI/CD pipelines:
```bash
cd ops/cicd
terraform destroy
```

(This won't affect your main infrastructure)

