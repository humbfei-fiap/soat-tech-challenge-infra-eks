terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "meu-eks-terraform-state--use1-az4--x-s3" # SUBSTITUA
    key            = "global/eks/terraform.tfstate"
    region         = "us-east-1" # SUBSTITUA
    dynamodb_table = "meu-eks-terraform-lock" # SUBSTITUA
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}