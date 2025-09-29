provider "kubernetes" {
  alias = "eks_cluster"

  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
  }
}

provider "helm" {
  alias = "eks_cluster"

  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
  }
}

# Recurso para esperar 60 segundos após a criação das políticas de acesso do EKS.
# Isso serve como um workaround para a latência de propagação das permissões no control plane.
resource "time_sleep" "wait_for_eks_auth_propagation" {
  depends_on = [
    aws_eks_access_policy_association.admin_user_policy,
    aws_eks_access_policy_association.apply_role_policy
  ]

  create_duration = "60s"
}

resource "helm_release" "ingress_nginx" {
  provider = helm.eks_cluster

  # Depende do recurso de espera, que por sua vez depende das políticas de acesso.
  depends_on = [
    time_sleep.wait_for_eks_auth_propagation
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
