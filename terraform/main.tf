################################################################################
# LOCALS
# Define valores locais para evitar repetição e garantir consistência.
################################################################################

locals {
  # Garante que o nome base do cluster não contenha o sufixo "-cluster",
  # evitando duplicação, já que o módulo EKS o adiciona.
  cluster_name = trimsuffix(var.cluster_name, "-cluster")
}

################################################################################
# MÓDULO DE REDE (VPC)
# Cria a VPC, subnets (públicas e privadas), NAT Gateway, etc.
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2" # Use uma versão específica para evitar quebras inesperadas

  name = "${local.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true # Use 'false' para alta disponibilidade em produção
  enable_dns_hostnames = true

  # Tags essenciais para que o EKS e os Load Balancers encontrem os recursos de rede corretos
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}

################################################################################
# RECURSO DE SEGURANÇA (KMS)
# Chave para criptografar os 'secrets' do Kubernetes dentro do etcd.
################################################################################

resource "aws_kms_key" "eks_secrets" {
  description             = "Chave KMS para criptografar secrets do cluster EKS ${local.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "${local.cluster_name}-secrets-key"
  }
}

################################################################################
# MÓDULO DO CLUSTER KUBERNETES (EKS)
# Provisiona o control plane, node groups e configurações de segurança.
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0" # Use uma versão específica

  cluster_name    = local.cluster_name
  # A versão 1.32 ainda não está disponível no EKS.
  # Usando a versão estável mais recente (1.29).
  cluster_version = "1.29"

  # Associa o cluster com a VPC criada pelo módulo "vpc"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets # Coloca os nodes nas subnets privadas

  # --- Configurações Críticas de Segurança ---

  # Torna o endpoint da API do Kubernetes acessível apenas de dentro da VPC.
  # Impede a exposição do control plane para a internet.
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  # Habilita logs essenciais para auditoria, debug e análise de segurança
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Configura a criptografia de envelope para os secrets do Kubernetes usando nossa chave KMS
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks_secrets.arn
    resources        = ["secrets"]
  }

  # Habilita o provedor OIDC do cluster, que é o pré-requisito para
  # usar o IAM Roles for Service Accounts (IRSA).
  enable_irsa = true

  # --- Configuração dos Worker Nodes ---
  
  eks_managed_node_group_defaults = {
    # Imagem otimizada para EKS com hardening de segurança da AWS
    ami_type                    = "AL2_x86_64"
    # Garante que os nós sejam criados apenas nas subnets privadas
    subnet_ids                  = module.vpc.private_subnets
  }

  eks_managed_node_groups = {
    default_nodes = {
      instance_types = var.instance_types
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
    Project     = "MeuProjeto"
  }
}