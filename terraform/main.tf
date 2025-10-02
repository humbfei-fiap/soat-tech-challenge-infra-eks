data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = data.aws_vpc.existing.id
  subnet_ids = data.aws_subnets.existing.ids

  cluster_endpoint_public_access = true

  access_entries = local.access_entries
  eks_managed_node_groups = {
    (var.node_group_name) = {
      name           = var.node_group_name
      instance_types = [var.node_instance_type]

      min_size     = var.node_min_capacity
      max_size     = var.node_max_capacity
      desired_size = var.node_desired_capacity
    }
  }
}

# Instala o AWS Load Balancer Controller usando Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1" # Use uma versão compatível com seu cluster

  values = [
    <<-EOT
clusterName: ${var.cluster_name}
serviceAccount:
  create: true
  name: aws-load-balancer-controller
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.aws_load_balancer_controller.arn}
EOT
  ]
}