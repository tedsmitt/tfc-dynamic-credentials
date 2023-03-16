terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "edintheclouds"
    workspaces {
      prefix = "app-"
    }
  }
  required_providers {
    aws = {
      version = "~> 4.0"
    }
  }
}
