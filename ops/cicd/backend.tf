terraform {
  backend "s3" {
    bucket = "final-apprentice-staging-terraform-state"
    key    = "cicd/terraform.tfstate"
    region = "us-east-1"
  }
}

