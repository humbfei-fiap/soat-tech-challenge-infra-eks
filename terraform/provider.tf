terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "meu-eks-terraform-state" # 
    key            = "global/eks/terraform.tfstate"
    region         = "us-east-1" # SUBSTITUA
    dynamodb_table = "meu-eks-terraform-lock-001" # 
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}