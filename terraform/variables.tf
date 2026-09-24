variable "aws_region" {
    description = "AWS region for the production environment"
    type = string
    default = "ap-south-2"
}

variable "environment" {
    description = "Deployment Environment"
    type = string
    default = "prod"
}

variable "datadog_api_url" {
    description = "Datadog API URL"
    type = string
    default = "https://app.datadoghq.eu/"
}