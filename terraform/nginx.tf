# Obtém um token de autenticação para o cluster.
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# Cria um arquivo kubeconfig local temporário com as credenciais do cluster.
resource "local_file" "kubeconfig" {
  content = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "eks"
    clusters = [{
      name = module.eks.cluster_id
      cluster = {
        server                   = module.eks.cluster_endpoint
        certificate-authority-data = module.eks.cluster_certificate_authority_data
      }
    }]
    contexts = [{
      name = "eks"
      context = {
        cluster = module.eks.cluster_id
        user    = "eks"
      }
    }]
    users = [{
      name = "eks"
      user = {
        token = data.aws_eks_cluster_auth.cluster.token
      }
    }]
  })
  filename = "${path.cwd}/kubeconfig.yaml"
}

# Configura o provedor Kubernetes para usar o arquivo kubeconfig gerado.
provider "kubernetes" {
  alias      = "eks_cluster"
  kubeconfig = local_file.kubeconfig.filename
}

# Configura o provedor Helm para usar o arquivo kubeconfig gerado.
provider "helm" {
  alias = "eks_cluster"
  kubernetes = {
    kubeconfig = local_file.kubeconfig.filename
  }
}

# Instala o ingress-nginx usando a configuração de provedor com alias.
resource "helm_release" "ingress_nginx" {
  provider = helm.eks_cluster

  # Garante que a instalação só ocorra após o kubeconfig e as políticas de acesso existirem.
  depends_on = [
    local_file.kubeconfig,
    aws_eks_access_policy_association.admin_user_policy,
    aws_eks_access_policy_association.apply_role_policy
  ]

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "kube-system"
  version    = "4.10.0"

  values = [
    yamlencode({
      controller = {
        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }
        service = {
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal"
          }
        }
      }
    })
  ]
}
