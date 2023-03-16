terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "edintheclouds"

    workspaces {
      name = "tfc-dynamic-credentials"
    }
  }
  required_providers {
    tfe = {
      version = "~> 0.42.0"
    }
    aws = {
      version = "~> 4.0"
    }
  }
}
