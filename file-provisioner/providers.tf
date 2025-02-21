terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "<Your-s3-bucket-name>"
    key    = "file_provisioner/terraform.tfstate"
    region = "<Your-region>"
  }
}

provider "aws" {
  region = "<Your-region>"
}