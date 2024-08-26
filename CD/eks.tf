
provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
locals {
  control_plane_subnet_ids = [for subnet_id in data.aws_subnets.default.ids : subnet_id if subnet_id != "subnet-08b87a54f88120c9e"] #subnet in az e does not support create control plane for now
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "sd5184-cd"
  cluster_version = "1.30"
  control_plane_subnet_ids = local.control_plane_subnet_ids
  vpc_id          = data.aws_vpc.default.id
  subnet_ids      = data.aws_subnets.default.ids
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true
  eks_managed_node_group_defaults = {
    instance_types = ["t2.medium"]
  }
  eks_managed_node_groups = {
    sd5184_cd = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.medium"]

      min_size     = 1
      max_size     = 1
      desired_size = 1
    }
  }
}


output "vpc_ids" {
  value = data.aws_vpc.default.id
}

output "aws_subnet_ids_id" {
  value = data.aws_subnets.default.ids
}

output "eks_endpoint" {
  description = "The endpoint for the EKS control plane"
  value       = module.eks.cluster_endpoint
}
