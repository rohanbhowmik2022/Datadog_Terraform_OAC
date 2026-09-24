terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    datadog = {
        source = "Datadog/datadog"
        version = "~> 4.0"
    }
  }
  backend "s3" {
    # Configure after the bootstrap S3 bucket is created
    # bucket = "..."
    # key = "datadog-terraform-oac/terraform.tfstate"
    # region = "ap-south-1"
    # use_lockfile = true
  }
}