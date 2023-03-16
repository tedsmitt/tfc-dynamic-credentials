variable "stage" {
  type = string
}

data "terraform_remote_state" "networking" {
  backend = "remote"
  config = {
    organization = "edintheclouds"
    workspaces = {
      name = "networking-${var.stage}"
    }
  }
}

resource "aws_security_group" "app" {
  name        = "app-${var.stage}"
  description = "Allow inbound traffic from App Runner"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc.vpc_id

  ingress {
    description = "Allow inbound traffic from App Runner"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_apprunner_vpc_connector" "connector" {
  vpc_connector_name = "app-${var.stage}-connector"
  subnets            = data.terraform_remote_state.networking.outputs.vpc.public_subnets
  security_groups    = [aws_security_group.app.id]
}

resource "aws_apprunner_service" "app" {
  service_name = "app-${var.stage}"

  source_configuration {
    image_repository {
      image_configuration {
        port = "8000"
      }
      image_identifier      = "public.ecr.aws/aws-containers/hello-app-runner:latest"
      image_repository_type = "ECR_PUBLIC"
    }
    auto_deployments_enabled = false
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = true
    }
    egress_configuration {
      egress_type      = "VPC"
      vpc_connector_id = aws_apprunner_vpc_connector.connector.id
    }
  }

  tags = {
    Name = "app-${var.stage}"
  }
}

output "app_runner_endpoint" {
  value = aws_apprunner_service.app.service_url
}
