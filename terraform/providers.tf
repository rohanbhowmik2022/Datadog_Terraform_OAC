provider "aws" {
    region = var.aws_region
    default_tags {
        tags = {
            Environment = var.environment
            ManagedBy = "Terraform"
            Project = "datadog-observability-oac"
        }
    }
}

provider "datadog" {
    api_url = var.datadog_api_url
}