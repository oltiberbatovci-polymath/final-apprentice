# Outputs for CI/CD module

# CodeStar Connection
output "codestar_connection_arn" {
  description = "ARN of the CodeStar Connection to GitHub"
  value       = "arn:aws:codeconnections:us-east-1:264765155009:connection/b824b735-4a6e-4881-ad89-3a7879f77536"
}

output "codestar_connection_status" {
  description = "Status of the CodeStar Connection"
  value       = "AVAILABLE"
}

# Pipeline outputs
output "terraform_pipeline_name" {
  description = "Name of the Terraform CodePipeline"
  value       = aws_codepipeline.terraform.name
}

output "terraform_pipeline_arn" {
  description = "ARN of the Terraform CodePipeline"
  value       = aws_codepipeline.terraform.arn
}

output "frontend_pipeline_name" {
  description = "Name of the Frontend CodePipeline"
  value       = aws_codepipeline.frontend.name
}

output "frontend_pipeline_arn" {
  description = "ARN of the Frontend CodePipeline"
  value       = aws_codepipeline.frontend.arn
}

output "backend_pipeline_name" {
  description = "Name of the Backend CodePipeline"
  value       = aws_codepipeline.backend.name
}

output "backend_pipeline_arn" {
  description = "ARN of the Backend CodePipeline"
  value       = aws_codepipeline.backend.arn
}

# Shared resources
output "artifacts_bucket_name" {
  description = "Name of the S3 bucket used for pipeline artifacts"
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket used for pipeline artifacts"
  value       = aws_s3_bucket.artifacts.arn
}

# Build project outputs
output "terraform_build_project_name" {
  description = "Name of the Terraform CodeBuild project"
  value       = aws_codebuild_project.terraform.name
}

output "frontend_build_project_name" {
  description = "Name of the Frontend CodeBuild project"
  value       = aws_codebuild_project.frontend.name
}

output "backend_build_project_name" {
  description = "Name of the Backend CodeBuild project"
  value       = aws_codebuild_project.backend.name
}

# IAM role outputs
output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline service role"
  value       = aws_iam_role.codepipeline.arn
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild service role"
  value       = aws_iam_role.codebuild.arn
}
