variable "stage" {
  type = string
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "vpc-${var.stage}"
  cidr   = "10.0.0.0/16"
}

output "vpc" {
  value = module.vpc
}
