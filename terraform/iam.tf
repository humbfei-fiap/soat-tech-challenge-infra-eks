#==============================================================================
# Controle de Acesso ao Cluster (Usuários e Roles)
#==============================================================================

locals {
  # Define aqui as permissões de acesso ao cluster.
  # Adicione usuários ou roles da AWS que precisarão de acesso.
  access_entries = {
    # Permissão para o usuário que está criando o cluster
    cluster_creator = {
      principal_arn = "arn:aws:iam::239409137076:user/user_aws"
      policy_associations = {
        cluster-admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    # Adicione outras entradas de acesso aqui, se necessário.
    # Exemplo para uma role:
    # another-role = {
    #   principal_arn = "arn:aws:iam::239409137076:role/another-role"
    #   policy_associations = {
    #     developer = {
    #       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSDeveloperPolicy"
    #       access_scope = {
    #         type = "namespace"
    #         namespaces = ["default"]
    #       }
    #     }
    #   }
    # }
  }
}

#==============================================================================
# Papel do IAM para o AWS Load Balancer Controller (IRSA)
#==============================================================================

# Baixa a política de permissão recomendada pela AWS para o controller.
data "http" "aws_load_balancer_controller_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

# Cria a política do IAM com o conteúdo baixado.
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  description = "Política para o AWS Load Balancer Controller"
  policy      = data.http.aws_load_balancer_controller_iam_policy.response_body
}

# Cria o papel do IAM que será usado pelo Service Account do controller no Kubernetes.
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.cluster_name}-aws-load-balancer-controller"

  # A "Assume Role Policy" confia no provedor OIDC do cluster EKS.
  # Isso permite que o Service Account do Kubernetes assuma este papel.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # Limita o acesso apenas ao Service Account do controller
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# Anexa a política ao papel.
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
}