# ------------------------------------------------------------
# Datadog AWS Integration
# ------------------------------------------------------------

data "datadog_integration_aws_iam_permissions" "datadog" {}

# Datadog publishes the required IAM actions through the
# provider. Split them into multiple policies because AWS IAM
# managed policy documents have size limits.

locals {
  # Role name is a plain string so the Datadog account resource does not
  # need to reference aws_iam_role (which would create a dependency cycle,
  # since the role's trust policy needs the account's external ID).
  datadog_role_name = "DatadogIntegrationRole"

  datadog_all_permissions = data.datadog_integration_aws_iam_permissions.datadog.iam_permissions

  datadog_target_policy_size = 5900

  datadog_permission_sizes = [
    for permission in local.datadog_all_permissions :
    length(permission) + 3
  ]

  datadog_cumulative_sizes = [
    for i in range(length(local.datadog_permission_sizes)) :
    sum(slice(local.datadog_permission_sizes, 0, i + 1))
  ]

  datadog_chunk_assignments = [
    for cumulative_size in local.datadog_cumulative_sizes :
    floor(cumulative_size / local.datadog_target_policy_size)
  ]

  datadog_chunk_numbers = distinct(local.datadog_chunk_assignments)

  datadog_permission_chunks = [
    for chunk_number in local.datadog_chunk_numbers : [
      for i, permission in local.datadog_all_permissions :
      permission if local.datadog_chunk_assignments[i] == chunk_number
    ]
  ]
}

# ------------------------------------------------------------
# Datadog IAM Policies
# ------------------------------------------------------------

data "aws_iam_policy_document" "datadog_integration" {
  count = length(local.datadog_permission_chunks)

  statement {
    effect = "Allow"

    actions = local.datadog_permission_chunks[count.index]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "datadog_integration" {
  count = length(local.datadog_permission_chunks)

  name = "DatadogAWSIntegrationPolicy-${count.index + 1}"

  policy = data.aws_iam_policy_document.datadog_integration[count.index].json

  tags = {
    Project     = "Datadog-Terraform-OAC"
    Environment = "prod"
    ManagedBy   = "Terraform"
    Purpose     = "Datadog AWS Integration"
  }
}

# ------------------------------------------------------------
# Datadog Integration Role Trust Policy
# ------------------------------------------------------------

data "aws_iam_policy_document" "datadog_integration_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "AWS"

      # Datadog commercial AWS account
      identifiers = [
        "arn:aws:iam::464622532012:root"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        datadog_integration_aws_account.datadog.auth_config.aws_auth_config_role.external_id
      ]
    }
  }
}

# ------------------------------------------------------------
# Datadog Integration IAM Role
# ------------------------------------------------------------

resource "aws_iam_role" "datadog_integration" {
  name = local.datadog_role_name

  description = "IAM role assumed by Datadog for AWS monitoring"

  assume_role_policy = data.aws_iam_policy_document.datadog_integration_assume_role.json

  tags = {
    Project     = "Datadog-Terraform-OAC"
    Environment = "prod"
    ManagedBy   = "Terraform"
    Purpose     = "Datadog AWS Integration"
  }
}

# Attach dynamically generated Datadog policies.

resource "aws_iam_role_policy_attachment" "datadog_integration" {
  count = length(aws_iam_policy.datadog_integration)

  role = aws_iam_role.datadog_integration.name

  policy_arn = aws_iam_policy.datadog_integration[count.index].arn
}

# Datadog recommends SecurityAudit in addition to the
# integration permissions.

resource "aws_iam_role_policy_attachment" "datadog_security_audit" {
  role = aws_iam_role.datadog_integration.name

  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# ------------------------------------------------------------
# Datadog AWS Integration
# ------------------------------------------------------------

resource "datadog_integration_aws_account" "datadog" {
  account_tags = [
    "env:prod",
    "managed-by:terraform"
  ]

  aws_account_id = var.aws_account_id

  aws_partition = "aws"

  aws_regions {
    include_all = true
  }

  auth_config {
    aws_auth_config_role {
      # Use the local, NOT aws_iam_role.datadog_integration.name,
      # otherwise Terraform reports a cycle.
      role_name = local.datadog_role_name
    }
  }

  resources_config {
    cloud_security_posture_management_collection = false
    extended_collection                          = true
  }

  traces_config {
    xray_services {}
  }

  logs_config {
    lambda_forwarder {
      lambdas = [
        module.datadog_log_forwarder.datadog_forwarder_arn
      ]
    }
  }

  metrics_config {
    namespace_filters {}
  }
}