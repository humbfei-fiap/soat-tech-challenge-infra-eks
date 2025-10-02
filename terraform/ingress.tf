# Define o Deployment do Ingress
resource "kubernetes_deployment" "ingress_deployment" {
  metadata {
    name = "ingress-deployment"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "ingress-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "ingress-app"
        }
      }
      spec {
        container {
          image = "ealen/echo-server"
          name  = "ingress-container"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Define o Service do tipo LoadBalancer para expor o Ingress com um NLB
resource "kubernetes_service" "ingress_service" {
  metadata {
    name = "ingress-service"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"           = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"         = "internet-facing"
    }
  }
  spec {
    selector = {
      app = "ingress-app"
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "LoadBalancer"
  }
}
