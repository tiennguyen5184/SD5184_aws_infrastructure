data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

provider "aws" {
  region = "us-east-1" # Default region 
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
  ami                  = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type        = "t2.micro" # Change this to your desired instance type
  security_groups      = [aws_security_group.ci_aws_security_group.name]
  user_data            = file("${path.module}/docker-install.sh")
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  root_block_device {
    volume_size = 30 # Size in GB
  }

  tags = {
    Name = "ci-server"
  }
}

resource "aws_iam_policy" "ec2_policy" {
  name = "ec2_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr-public:PutLifecyclePolicy",
          "ecr-public:PutImageTagMutability",
          "ecr-public:StartImageScan",
          "ecr-public:CreateRepository",
          "ecr-public:PutImageScanningConfiguration",
          "ecr-public:UploadLayerPart",
          "ecr-public:BatchDeleteImage",
          "ecr-public:DeleteLifecyclePolicy",
          "ecr-public:DeleteRepository",
          "ecr-public:PutImage",
          "ecr-public:CompleteLayerUpload",
          "ecr-public:StartLifecyclePolicyPreview",
          "ecr-public:InitiateLayerUpload",
          "ecr-public:DeleteRepositoryPolicy",
          "ecr-public:GetAuthorizationToken"
        ],
        "Resource" : "arn:aws:ecr:us-east-1:091137845411:repository/sd5184_msa"
      },
      {
        "Effect" : "Allow",
        "Action" : "ecr-public:GetAuthorizationToken",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "sts:GetServiceBearerToken",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "ecr-public:BatchCheckLayerAvailability",
        "Resource" : "arn:aws:ecr:us-east-1:091137845411:repository/sd5184_msa"
      }
    ]
  })
}
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
            
    ]
  })
}