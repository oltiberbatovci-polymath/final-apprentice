terraform {
  backend "s3" {
    bucket = "group1-task-bucket123123123"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}
