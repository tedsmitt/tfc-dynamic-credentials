variable "github_oauth_app_id" {
  type = string
}

locals {
  stages         = ["dev", "prod"]
  tfc_thumbprint = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
  tfe_variables = {
    "TFC_AWS_PROVIDER_AUTH" = "true"
    "TFC_AWS_RUN_ROLE_ARN"  = aws_iam_role.terraform_cloud.arn
    "AWS_DEFAULT_REGION"    = "eu-west-1"
  }
}

# Data sources
data "tfe_organization" "main" {
  name = "edintheclouds"
}

data "tfe_oauth_client" "github" {
  organization = data.tfe_organization.main.name
  name         = "tedsmitt"
}

# AWS terraform_cloud Setup
resource "aws_iam_openid_connect_provider" "terraform_cloud" {
  url             = "https://app.terraform.io" #Assumes Terraform Cloud and not Terraform Enterprise
  thumbprint_list = [local.tfc_thumbprint]
  client_id_list  = ["aws.workload.identity"]
}

data "aws_iam_policy_document" "terraform_cloud" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.terraform_cloud.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "app.terraform.io:aud"
      values   = ["aws.workload.identity"]
    }
    condition {
      test     = "StringLike"
      variable = "app.terraform.io:sub"
      values   = ["organization:${data.tfe_organization.main.name}:project:*:workspace:*:run_phase:*"]
    }
  }
}

resource "aws_iam_role" "terraform_cloud" {
  name               = "terraform-cloud"
  assume_role_policy = data.aws_iam_policy_document.terraform_cloud.json
}

resource "aws_iam_role_policy_attachment" "terraform_cloud" {
  role       = aws_iam_role.terraform_cloud.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# TFC Variable Set
resource "tfe_variable_set" "aws_credentials" {
  name         = "AWS Credentials"
  global       = false
  organization = data.tfe_organization.main.name
}

resource "tfe_variable" "aws_credentials" {
  for_each        = local.tfe_variables
  key             = each.key
  value           = each.value
  category        = "env"
  variable_set_id = tfe_variable_set.aws_credentials.id
}

# TFC Workspaces
# Networking
resource "tfe_workspace" "networking" {
  for_each                      = toset(local.stages)
  name                          = "networking-${each.value}"
  organization                  = data.tfe_organization.main.name
  tag_names                     = ["networking", each.value]
  structured_run_output_enabled = false
  global_remote_state           = true

  vcs_repo {
    identifier     = "tedsmitt/tfc-dynamic-credentials"
    oauth_token_id = data.tfe_oauth_client.github.oauth_token_id
    branch         = "main"
  }
  working_directory = "2-networking"
  trigger_prefixes  = ["2-networking"]
}

resource "tfe_workspace_variable_set" "networking" {
  for_each        = tfe_workspace.networking
  workspace_id    = each.value.id
  variable_set_id = tfe_variable_set.aws_credentials.id
}

resource "tfe_variable" "networking_env" {
  for_each     = toset(local.stages)
  key          = "stage"
  value        = each.value
  category     = "terraform"
  workspace_id = tfe_workspace.networking[each.key].id
}

# App
resource "tfe_workspace" "app" {
  for_each                      = toset(local.stages)
  name                          = "app-${each.value}"
  organization                  = data.tfe_organization.main.name
  tag_names                     = ["app", each.value]
  structured_run_output_enabled = false

  vcs_repo {
    identifier     = "tedsmitt/tfc-dynamic-credentials"
    oauth_token_id = data.tfe_oauth_client.github.oauth_token_id
    branch         = "main"
  }
  working_directory = "3-app"
  trigger_prefixes  = ["3-app"]
}

resource "tfe_workspace_variable_set" "app" {
  for_each        = tfe_workspace.app
  workspace_id    = each.value.id
  variable_set_id = tfe_variable_set.aws_credentials.id
}

resource "tfe_variable" "app_env" {
  for_each     = toset(local.stages)
  key          = "stage"
  value        = each.value
  category     = "terraform"
  workspace_id = tfe_workspace.app[each.key].id
}
