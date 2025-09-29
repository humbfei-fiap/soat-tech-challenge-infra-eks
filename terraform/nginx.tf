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

resource "helm_release" "ingress_nginx" {
  provider = helm.eks_cluster

  # Garante que o EKS e o IRSA estejam prontos antes de instalar o Helm chart
  depends_on = [module.eks.cluster_id, aws_eks_access_policy_association.admin_user_policy, aws_eks_access_policy_association.apply_role_policy]

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "kube-system"
  version    = "4.10.0" # Especifica uma versão para consistência

  values = [
    yamlencode({
      controller = {
        # Garante que o Ingress Controller seja executado nos nós do EKS
        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }
        # Configurações para criar um Network Load Balancer (NLB) INTERNO na AWS
        service = {
          annotations = {
            # Especifica o tipo de Load Balancer como NLB para alta performance
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            # Define o NLB como interno, pois o cluster não tem acesso público
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal"
          }
        }
      }
    })
  ]
}