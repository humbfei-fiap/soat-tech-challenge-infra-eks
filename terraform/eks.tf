module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # ===================================================
  # CONFIGURAÇÕES DE SEGURANÇA IMPORTANTES
  # ===================================================
  cluster_endpoint_private_access = true # Acesso ao API Server apenas de dentro da VPC
  cluster_endpoint_public_access  = false # Desabilita acesso público ao API Server

  # Habilita logs essenciais para auditoria e segurança
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Criptografia de secrets do Kubernetes com uma chave KMS gerenciada pela AWS
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks_secrets.arn
    resources        = ["secrets"]
  }

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
resource "aws_kms_key" "eks_secrets" {
  description             = "Chave KMS para criptografar secrets do EKS"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Output para configurar o kubectl depois
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}