provider "aws" {
  region = var.aws_region


  default_tags {
    tags = {
      Project     = "Datadog-Terraform-OAC"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}