# ------------------------------------------------------------
# Datadog Log Forwarder
# ------------------------------------------------------------

module "datadog_log_forwarder" {
  source  = "DataDog/log-lambda-forwarder-datadog/aws"
  version = "2.0.4"

  # The API key is supplied through the Terraform variable.
  # The module stores it in AWS Secrets Manager.
  dd_api_key = var.datadog_api_key

  dd_site = "datadoghq.eu"

  create_dd_api_key_secret = true

  tags = {
    Project     = "Datadog-Terraform-OAC"
    Environment = "prod"
    ManagedBy   = "Terraform"
    Purpose     = "Datadog Log Forwarder"
  }
}