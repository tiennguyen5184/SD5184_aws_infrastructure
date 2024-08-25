terraform {
  backend "s3" {
    bucket  = "sd5184-terraform-backend"
    key     = "ci/ci.tfstate"
    region  = "us-east-1"
    encrypt = false
  }
}
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

provider "aws" {
  region =  "us-east-1" # Default region 
}

resource "aws_security_group" "ci_aws_security_group" {
  name        = "ci_aws_security_group"
  description = "CI security group"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ci-server" {
  ami             = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type   = "t2.micro" # Change this to your desired instance type
  security_groups = [aws_security_group.ci_aws_security_group.name]
  user_data       = "${file("${path.module}/docker-install.sh")}"
  root_block_device {
    volume_size = 30  # Size in GB
  }

  tags = {
    Name = "ci-server"
  }
}

