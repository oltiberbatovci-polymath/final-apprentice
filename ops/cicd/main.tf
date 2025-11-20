# CI/CD Pipeline Modules

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Use existing CodeStar Connection for GitHub (AVAILABLE)
# User specified connection
locals {
  github_connection_arn = "arn:aws:codeconnections:us-east-1:522814722683:connection/4e86954b-fdcd-4f72-963a-1e73346bba35"
}

# S3 bucket for pipeline artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket        = "final-apprentice-staging-cicd-artifacts-${random_string.suffix.result}"
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# CodeBuild projects
resource "aws_codebuild_project" "terraform" {
  name         = "final-apprentice-staging-terraform"
  description  = "Terraform infrastructure build project"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_BACKEND_BUCKET"
      value = var.terraform_state_bucket
    }

    environment_variable {
      name  = "TF_BACKEND_KEY"
      value = var.terraform_state_key
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ops/cicd/infrastructure/buildspec-terraform.yml"
  }

  tags = var.tags
}

resource "aws_codebuild_project" "frontend" {
  name         = "final-apprentice-staging-frontend"
  description  = "Frontend web application build and deploy project"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "FRONTEND_BUCKET"
      value = var.frontend_bucket_name
    }

    environment_variable {
      name  = "CLOUDFRONT_DIST_ID"
      value = var.cloudfront_distribution_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ops/cicd/web/buildspec-frontend.yml"
  }

  tags = var.tags
}

resource "aws_codebuild_project" "backend" {
  name         = "final-apprentice-staging-backend"
  description  = "Backend API build and deploy project"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ECR_REGISTRY"
      value = split("/", var.ecr_repository_url)[0]
    }

    environment_variable {
      name  = "ECR_REPOSITORY"
      value = split("/", var.ecr_repository_url)[1]
    }

    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      value = var.ecs_cluster_name
    }

    environment_variable {
      name  = "ECS_SERVICE_NAME"
      value = var.ecs_service_name
    }

    environment_variable {
      name  = "ECS_TASK_FAMILY"
      value = var.ecs_service_name
    }

    environment_variable {
      name  = "ECS_EXECUTION_ROLE_ARN"
      value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.ecs_cluster_name}-ecs-task-execution"
    }

    environment_variable {
      name  = "ECS_TASK_ROLE_ARN"
      value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.ecs_cluster_name}-ecs-task-execution"
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = "api"
    }

    environment_variable {
      name  = "CLOUDWATCH_LOG_GROUP"
      value = "/ecs/${var.ecs_service_name}"
    }

    environment_variable {
      name  = "DATABASE_URL"
      value = "postgresql://postgres:b9*6H[oU#BeezqOL@task-api-dev123141241-db-primary.cqb8wccsmbby.us-east-1.rds.amazonaws.com:5432/infrastructure"
    }

    environment_variable {
      name  = "ALB_DNS_NAME"
      value = "task-alb-dev123141241-1337149599.us-east-1.elb.amazonaws.com"
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ops/cicd/api/buildspec-backend.yml"
  }

  tags = var.tags
}

# CodePipeline for Infrastructure
resource "aws_codepipeline" "terraform" {
  name     = "final-apprentice-staging-terraform-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["terraform_source"]

      configuration = {
        ConnectionArn        = local.github_connection_arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = "TerraformPlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["terraform_source"]
      output_artifacts = ["terraform_plan"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.terraform.name
        EnvironmentVariables = jsonencode([
          {
            name  = "TF_COMMAND"
            value = "plan"
          }
        ])
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Apply"

    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["terraform_source"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.terraform.name
        EnvironmentVariables = jsonencode([
          {
            name  = "TF_COMMAND"
            value = "apply"
          }
        ])
      }
    }
  }

  tags = var.tags
}

# CodePipeline for Frontend
resource "aws_codepipeline" "frontend" {
  name     = "final-apprentice-staging-frontend-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["frontend_source"]

      configuration = {
        ConnectionArn        = local.github_connection_arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }


  stage {
    name = "Build"

    action {
      name             = "FrontendBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["frontend_source"]
      output_artifacts = ["frontend_build"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.frontend.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "FrontendDeploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      # Use the source artifact so the buildspec file is present in the container
      input_artifacts  = ["frontend_source"]
      output_artifacts = []
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.frontend.name
      }
    }
  }

  tags = var.tags
}

# CodePipeline for Backend
resource "aws_codepipeline" "backend" {
  name     = "final-apprentice-staging-backend-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["backend_source"]

      configuration = {
        ConnectionArn        = local.github_connection_arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BackendBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["backend_source"]
      output_artifacts = ["backend_build"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.backend.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "BackendDeploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["backend_build"]
      output_artifacts = []
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.backend.name
      }
    }
  }

  stage {
    name = "Test"

    action {
      name             = "BackendTest"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["backend_build"]
      output_artifacts = []
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.backend.name
      }
    }
  }

  tags = var.tags
}
