terraform {
  backend "s3" {
    bucket         = "soat-tech-challenge-tf-state-humberto"
    key            = "soat-tech-challenge-infra-eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "soat-tech-challenge-tf-state-lock-humberto"
  }
}
