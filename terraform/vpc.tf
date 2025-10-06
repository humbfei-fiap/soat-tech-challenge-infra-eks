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

# Garante que as sub-redes existentes tenham as tags necessárias para o Load Balancer Controller
resource "aws_ec2_tag" "subnet_cluster_tag" {
  for_each = toset(data.aws_subnets.existing.ids)

  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "subnet_elb_role_tag" {
  for_each = toset(data.aws_subnets.existing.ids)

  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "subnet_internal_elb_role_tag" {
  for_each = toset(data.aws_subnets.existing.ids)

  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}
