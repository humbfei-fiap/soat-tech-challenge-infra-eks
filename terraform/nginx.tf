
resource "helm_release" "ingress_nginx" {
  # Garante que o EKS e o IRSA estejam prontos antes de instalar o Helm chart
  depends_on = [module.eks.cluster_id]

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
