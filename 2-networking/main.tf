variable "stage" {
  type = string
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = "vpc-${var.stage}"
  cidr           = "10.0.0.0/16"
  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Name = "vpc-${var.stage}"
  }
}

output "vpc" {
  value = module.vpc
}
