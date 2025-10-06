
#==============================================================================
# External Secrets Operator (ESO)
# Instala o ESO e configura as permissões necessárias para ler segredos
# do AWS Secrets Manager usando IRSA (IAM Roles for Service Accounts).
#==============================================================================

# 1. Política de Permissão do IAM para o External Secrets
#------------------------------------------------------------------------------
# Esta política concede ao External Secrets a permissão para acessar
# segredos no AWS Secrets Manager.
resource "aws_iam_policy" "external_secrets" {
  name        = "${var.cluster_name}-ExternalSecretsIAMPolic"
  description = "Permite que o External Secrets acesse o AWS Secrets Manager."

  # A política permite as ações GetSecretValue e DescribeSecret.
  # [!! IMPORTANTE !!] Por segurança, o ideal é restringir o "Resource"
  # para os ARNs específicos dos segredos que você vai usar.
  # Exemplo: "arn:aws:secretsmanager:*:*:secret:minha-app/*"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "*" # ATENÇÃO: Permite acesso a todos os segredos. Restrinja em produção.
      },
    ]
  })
}

# 2. Papel do IAM (Role) para o Service Account do External Secrets
#------------------------------------------------------------------------------
# Este papel será "assumido" pelo Service Account do Kubernetes, permitindo
# que os pods do External Secrets usem as permissões da política acima.
resource "aws_iam_role" "external_secrets" {
  name = "${var.cluster_name}-external-secrets-role"

  # A política de confiança (Assume Role Policy) permite que o provedor OIDC
  # do cluster EKS conceda a identidade deste papel a um Service Account.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          # Confia no provedor OIDC do nosso cluster EKS.
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # Condição que limita qual Service Account pode assumir este papel.
            # O formato é: system:serviceaccount:<namespace>:<serviceaccount_name>
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          }
        }
      }
    ]
  })
}

# 3. Anexa a Política ao Papel
#------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "external_secrets" {
  policy_arn = aws_iam_policy.external_secrets.arn
  role       = aws_iam_role.external_secrets.name
}

# 4. Instalação do External Secrets via Helm Chart
#------------------------------------------------------------------------------
# Este recurso gerencia a instalação do chart do Helm.
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "external-secrets"
  create_namespace = true
  version    = "0.20.1" # Versão mais recente para suportar a API v1

  # Garante que o papel do IAM e as permissões de acesso ao cluster
  # existam antes de tentar instalar o chart.
  depends_on = [
    aws_iam_role.external_secrets,
    module.eks.access_policy_associations
  ]

  # Valores customizados para o chart.
  values = [
    <<-EOT
# Cria um Service Account com o nome 'external-secrets'.
serviceAccount:
  create: true
  name: "external-secrets"
  # A anotação crucial que vincula o Service Account ao Papel do IAM.
  annotations:
    "eks.amazonaws.com/role-arn": "${aws_iam_role.external_secrets.arn}"

# Instala as CRDs (Custom Resource Definitions) necessárias.
installCRDs: true
EOT
  ]
}
