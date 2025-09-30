variable "aws_region" {
  description = "A região da AWS onde os recursos serão criados."
  type        = string
}

variable "cluster_name" {
  description = "O nome do cluster EKS."
  type        = string
}

variable "vpc_id" {
  description = "O ID da VPC existente onde o cluster será implantado."
  type        = string
}

variable "subnet_ids" {
  description = "Uma lista de IDs de sub-redes existentes para os nós do EKS."
  type        = list(string)
}

variable "node_instance_type" {
  description = "O tipo de instância EC2 para os nós de trabalho."
  type        = string
}

variable "node_group_name" {
  description = "O nome do grupo de nós gerenciados do EKS."
  type        = string
}

variable "node_desired_capacity" {
  description = "O número desejado de nós no grupo."
  type        = number
}

variable "node_min_capacity" {
  description = "O número mínimo de nós no grupo."
  type        = number
}

variable "node_max_capacity" {
  description = "O número máximo de nós no grupo."
  type        = number
}

variable "cluster_version" {
  description = "A versão do Kubernetes para o cluster EKS."
  type        = string
}
