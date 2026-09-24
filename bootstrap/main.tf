data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name        = "GitHub-Actions-OIDC"
    Project     = "Datadog-Terraform-OAC"
    Environment = "prod"
  }
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
      ]
    }
  }
}

resource "aws_iam_role" "terraform_deployment" {
  name = var.terraform_role_name

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  description = "Terraform deployment role assumed by GitHub Actions using OIDC"

  tags = {
    Project     = "Datadog-Terraform-OAC"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

data "aws_iam_policy_document" "terraform_deployment" {
  statement {
    effect = "Allow"

    actions = [
      "iam:*",
      "s3:*",
      "lambda:*",
      "logs:*",
      "apigateway:*",
      "cloudwatch:*",
      "route53:*",
      "sqs:*",
      "sns:*",
      "ec2:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "terraform_deployment" {
  name = "TerraformDeploymentPolicy"

  role = aws_iam_role.terraform_deployment.id

  policy = data.aws_iam_policy_document.terraform_deployment.json
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform_state_bucket

  tags = {
    Name        = "Terraform State"
    Project     = "Datadog-Terraform-OAC"
    Environment = "prod"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}