terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }

  backend "s3" {
    bucket         = "meu-eks-terraform-state"
    key            = "global/eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "meu-eks-terraform-lock-001"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}


