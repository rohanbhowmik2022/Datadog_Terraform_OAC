variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in OWNER/REPOSITORY format"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to deploy"
  type        = string
  default     = "main"
}

variable "terraform_role_name" {
  description = "IAM role assumed by GitHub Actions"
  type        = string
  default     = "GitHubActions-Terraform-Deployment"
}

variable "terraform_state_bucket" {
  description = "S3 bucket used for Terraform state"
  type        = string
}