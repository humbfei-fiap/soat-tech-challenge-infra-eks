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

# Configuração moderna e correta para os providers se autenticarem no EKS.
# Eles usarão o endpoint público e um token de curta duração gerado pelo AWS CLI.

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = module.eks.cluster_certificate_authority_data
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
    }
  }
}
