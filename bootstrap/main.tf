data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# ------------------------------------------------------------
# GitHub Actions OIDC Provider
# ------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name        = "GitHub-Actions-OIDC"
    Project     = "Datadog-Terraform-OAC"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------
# GitHub Actions -> AWS Trust Policy
# ------------------------------------------------------------

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

    # GitHub Actions audience
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    # Restrict access to this exact repository and main branch.
    #
    # Repository:
    # rohanbhowmik2022/Datadog_Terraform_OAC
    #
    # Owner ID:
    # 109950268
    #
    # Repository ID:
    # 1383512990
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:rohanbhowmik2022@109950268/Datadog_Terraform_OAC@1383512990:ref:refs/heads/main",
        "repo:rohanbhowmik2022@109950268/Datadog_Terraform_OAC@1383512990:environment:production"
      ]
    }
  }
}

# ------------------------------------------------------------
# Terraform Deployment Role
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# Terraform Deployment Permissions
#
# NOTE:
# This is the initial bootstrap policy.
# We will reduce this to least privilege after the
# observability resources are established.
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# Terraform Remote State S3 Bucket
# ------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform_state_bucket

  tags = {
    Name        = "Terraform State"
    Project     = "Datadog-Terraform-OAC"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------
# S3 Versioning
# ------------------------------------------------------------

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------
# S3 Server-Side Encryption
# ------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ------------------------------------------------------------
# S3 Public Access Protection
# ------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}