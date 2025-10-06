output "cluster_name" {
  description = "O nome do cluster EKS."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "O endpoint do servidor da API do Kubernetes do cluster EKS."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "O dado da autoridade de certificação do cluster, para configurar o kubectl."
  value       = module.eks.cluster_certificate_authority_data
}

output "configure_kubectl" {
  description = "Comando para configurar o kubectl para se conectar ao cluster."
  value = "aws eks --region ${var.aws_region} update-kubeconfig --name ${var.cluster_name}"
}

output "vpc_link_id" {
  description = "O ID do VPC Link criado."
  # Retorna o ID do VPC Link se ele for criado, ou uma string vazia caso contrário.
  value       = join("", aws_apigatewayv2_vpc_link.this.*.id)
}

output "nginx_nlb_hostname" {
  description = "O hostname do NLB compartilhado criado pelo NGINX Ingress Controller."
  value       = data.kubernetes_service.nginx_ingress_service.status[0].load_balancer[0].ingress[0].hostname
}

output "eks_managed_node_group_names" {
  description = "Os nomes dos grupos de nós gerenciados do EKS."
  value       = keys(module.eks.eks_managed_node_groups)
}