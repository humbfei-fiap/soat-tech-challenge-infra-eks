# ===============================================================
# Configurações Gerais
# ===============================================================
aws_region   = "us-east-1"
cluster_name = "soat-eks-cluster"
cluster_version = "1.33"

# ===============================================================
# Configurações de Rede (Valores que você já forneceu)
# ===============================================================
vpc_id     = "vpc-8ce247f1"
subnet_ids = ["subnet-8a652684", "subnet-c3f47da5"]

# ===============================================================
# Configurações do Grupo de Nós (Worker Nodes)
# ===============================================================
node_group_name       = "ng-primario"
node_instance_type    = "t3.medium"
node_desired_capacity = 2
node_min_capacity     = 1
node_max_capacity     = 3


