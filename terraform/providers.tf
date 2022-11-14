terraform {
  backend "s3" {
    profile = var.aws_profile
    bucket = var.aws_s3_backend_bucket_name
    key    = "terraform.tfstate"
    region = var.region
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.38.0"
    }
  }
}

provider "aws" {
  region = var.region
  profile = var.aws_profile
}