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
