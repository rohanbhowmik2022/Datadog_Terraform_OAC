variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "867041163196"
}

variable "datadog_api_key" {
  description = "Datadog API key used by the Datadog Forwarder"
  type        = string
  sensitive   = true
}