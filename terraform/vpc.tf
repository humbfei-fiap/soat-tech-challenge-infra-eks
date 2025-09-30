# Busca informações da VPC existente para ser usada pelo cluster EKS.
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Busca informações das sub-redes existentes.
data "aws_subnets" "existing" {
  filter {
    name   = "subnet-id"
    values = var.subnet_ids
  }
}
