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
  version = "~> 20.0" # ATUALIZADO

  cluster_name    = local.cluster_name
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # O modo de autenticação é novo na v20
  authentication_mode = "API_AND_CONFIG_MAP"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks_secrets.arn
    resources        = ["secrets"]
  }

  enable_irsa = true

  eks_managed_node_group_defaults = {
    ami_type   = "AL2_x86_64"
    subnet_ids = module.vpc.private_subnets
  }

  eks_managed_node_groups = {
    default_nodes = {
      instance_types = var.instance_types
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
    }
  }
}

################################################################################
# GERENCIAMENTO DO CONFIGMAP AWS-AUTH (MANUAL)
################################################################################

resource "kubernetes_config_map_v1_data" "aws_auth" {
  depends_on = [module.eks.cluster_id]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      for role in values(module.eks.eks_managed_node_groups) : {
        rolearn  = role.iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::239409137076:user/user_aws"
        username = "admin"
        groups   = ["system:masters"]
      }
    ])
  }
}