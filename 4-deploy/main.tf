terraform {
  required_providers {
    multispace = {
      source  = "mitchellh/multispace"
      version = "~> 0.1.0"
    }
  }
}

locals {
  stages                = ["dev", "prod"]
  tfc_organization_name = "edintheclouds"
}

resource "multispace_run" "networking" {
  for_each     = toset(local.stages)
  organization = local.tfc_organization_name
  workspace    = "networking-${each.value}"
}

resource "multispace_run" "app" {
  for_each     = toset(local.stages)
  organization = local.tfc_organization_name
  workspace    = "app-${each.value}"
  depends_on   = [multispace_run.networking]
}
