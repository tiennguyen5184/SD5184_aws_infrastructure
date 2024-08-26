terraform {
  backend "s3" {
    bucket  = "sd5184-terraform-backend"
    key     = "ci/ci.tfstate"
    region  = "us-east-1"
    encrypt = false
  }
}