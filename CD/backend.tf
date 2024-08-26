terraform {
  backend "s3" {
    bucket  = "sd5184-terraform-backend"
    key     = "cd/cd.tfstate"
    region  = "us-east-1"
    encrypt = false
  }
}