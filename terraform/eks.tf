

  # ===================================================
  # CONFIGURAÇÃO DOS WORKER NODES
  # ===================================================
  eks_managed_node_group_defaults = {
    # Imagem otimizada para EKS com hardening da AWS
    ami_type = "AL2_x86_64"
    # Não associar IP público aos nós
    associate_public_ip_address = false
    # Garante que os nós sejam criados nas subnets privadas
    subnet_ids = module.vpc.private_subnets
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
    }
  }

  # Habilita o OIDC provider para o cluster, necessário para o IRSA
  enable_irsa = true

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Chave KMS para criptografar os Secrets do Kubernetes
#resource "aws_kms_key" "eks_secrets" {
#  description             = "Chave KMS para criptografar secrets do EKS"
#  deletion_window_in_days = 7
#  enable_key_rotation     = true
#}

# Output para configurar o kubectl depois
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}