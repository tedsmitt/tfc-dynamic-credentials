terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "edintheclouds"

    workspaces {
      name = "test-workspace"
    }
  }
  required_providers {
    aws = {
      version = "~> 4.0"
    }
  }
}
