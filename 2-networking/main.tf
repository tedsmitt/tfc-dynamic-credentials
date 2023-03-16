module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
