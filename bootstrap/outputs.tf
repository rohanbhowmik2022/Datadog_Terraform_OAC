output "terraform_role_arn" {
  description = "IAM role assumed by GitHub Actions"
  value       = aws_iam_role.terraform_deployment.arn
}

output "terraform_state_bucket" {
  description = "Terraform state bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github.arn
}