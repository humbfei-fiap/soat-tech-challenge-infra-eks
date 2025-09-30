#==============================================================================
# Papéis para o Cluster e para os Nós (serão criados pelo módulo do EKS)
#==============================================================================
# O módulo terraform-aws-eks que usaremos no main.tf irá criar e anexar
# automaticamente os papéis e políticas corretas para o cluster e para os nós.
# Isso simplifica o código e garante que as permissões padrão sejam usadas.

#==============================================================================
# Papel do IAM para o AWS Load Balancer Controller (IRSA)
#==============================================================================

# Baixa a política de permissão recomendada pela AWS para o controller.
data "http" "aws_load_balancer_controller_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
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
