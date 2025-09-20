

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "region" {
  value = var.region
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}