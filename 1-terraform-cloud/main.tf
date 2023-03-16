variable "github_oauth_app_id" {
  type = string
}

# variable "github_oauth_app_token" {
#   type      = string
#   sensitive = true
# }

# variable "github_ssh_key_file_path" {
#   type = string
# }

locals {
  tfc_thumbprint = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"

  tfe_variables = {
    "TFC_AWS_PROVIDER_AUTH" = "true"
    "TFC_AWS_RUN_ROLE_ARN"  = aws_iam_role.terraform_cloud.arn
    "AWS_DEFAULT_REGION"    = "eu-west-1"
  }
}

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

# VCS Setup
# resource "tfe_oauth_client" "github" {
#   api_url          = "https://api.github.com"
#   http_url         = "https://github.com"
#   oauth_token      = var.github_oauth_app_token
#   service_provider = "github"
#   organization     = data.tfe_organization.main.name
# }

# resource "tfe_ssh_key" "github" {
#   name         = "github"
#   key          = file(var.github_ssh_key_file_path)
#   organization = data.tfe_organization.main.name
# }

# Workspaces
resource "tfe_workspace" "main" {
  name                          = "test-workspace"
  organization                  = data.tfe_organization.main.name
  tag_names                     = ["test"]
  working_directory             = "2-test-resources"
  structured_run_output_enabled = false
  vcs_repo {
    identifier     = "tedsmitt/tfc-dynamic-credentials"
    oauth_token_id = data.tfe_oauth_client.github.oauth_token_id
    branch         = "main"
  }
}

resource "tfe_variable" "vars" {
  for_each     = local.tfe_variables
  key          = each.key
  value        = each.value
  category     = "env"
  workspace_id = tfe_workspace.main.id
}
