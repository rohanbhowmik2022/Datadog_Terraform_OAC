locals {
  project = "datadog-terraform-oac"
  environment = "var.environment"
  region = "var.aws_region"
}

# common_tags = {
#     Project = local.project
#     Environment = local.environment
#     ManagedBy = "Terraform"
# }