
#==============================================================================
# NGINX Ingress Controller
# Instala o NGINX Ingress Controller, que atuará como o roteador central
# para todos os serviços dentro do cluster.
#==============================================================================
resource "helm_release" "nginx_ingress_controller" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true
  version    = "4.10.0" # Versão estável e recente

  depends_on = [module.eks.access_policy_associations]

  values = [
    <<-EOT
controller:
  service:
    # As anotações cruciais para criar um NLB INTERNO para o NGINX
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
EOT
  ]
}

#==============================================================================
# Data Source para o Serviço do NGINX
# Usamos este data source para "ler" o serviço que o Helm acabou de criar.
# Isso nos permite obter o endereço do NLB para usar em outros lugares (como no VPC Link).
#==============================================================================
data "kubernetes_service" "nginx_ingress_service" {
  # Garante que a leitura só aconteça depois que o Helm terminar a instalação
  depends_on = [helm_release.nginx_ingress_controller]

  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}
