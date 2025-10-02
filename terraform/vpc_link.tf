

# Passo 2: Criar o VPC Link que conecta o API Gateway ao NLB.
resource "aws_apigatewayv2_vpc_link" "eks_vpc_link" {
  

  name               = "${var.cluster_name}-vpclink"
  subnet_ids         = data.aws_subnets.existing.ids
  security_group_ids = [module.eks.node_security_group_id]
  

  tags = {
    "Terraform" = "true"
    "Name"      = "${var.cluster_name}-vpclink"
  }
}