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

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

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
  cluster_version = "1.28"

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
    # Não atribui IPs públicos aos nós de trabalho
    associate_public_ip_address = false
    # Garante que os nós sejam criados apenas nas subnets privadas
    subnet_ids                  = module.vpc.private_subnets
  }

  eks_managed_node_groups = {
    default_nodes = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
    Project     = "MeuProjeto"
  }
}