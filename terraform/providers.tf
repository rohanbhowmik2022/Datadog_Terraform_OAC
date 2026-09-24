terraform {
  backend "s3" {
    bucket = "datadog-terraform-oac-867041163196"
    key    = "prod/terraform.tfstate"
    region = "ap-south-2"

    use_lockfile = true
  }
}

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

provider "datadog" {
  api_url = "https://api.datadoghq.eu"
}   