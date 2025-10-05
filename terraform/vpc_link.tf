#==============================================================================
# VPC Link para o API Gateway
# Cria a conexão privada entre o API Gateway e a VPC onde o EKS está rodando.
#==============================================================================

resource "aws_apigatewayv2_vpc_link" "this" {
  # O VPC Link só será criado se a variável create_vpc_link for verdadeira.
  count = var.create_vpc_link ? 1 : 0

  # Garante que o NLB do NGINX exista antes de criar o link.
  depends_on = [data.kubernetes_service.nginx_ingress_service]

  name = "${var.cluster_name}-vpc-link"

  # Associa o VPC Link com as sub-redes onde o NLB interno será criado.
  subnet_ids = data.aws_subnets.existing.ids

  # Associa o VPC Link com os security groups para permitir a comunicação.
  # Aqui usamos o security group principal do cluster como exemplo.
  # Pode ser necessário ajustar para um SG mais específico dependendo da sua necessidade.
  security_group_ids = [
    module.eks.cluster_security_group_id
  ]

  tags = {
    Name = "${var.cluster_name}-vpc-link"
  }
}