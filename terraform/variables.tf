variable "aws_region" {
  description = "Região da AWS para criar os recursos"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
  default     = "eks-techchallenger"
}

variable "vpc_cidr" {
  description = "Bloco CIDR para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Lista de blocos CIDR para as sub-redes públicas."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Lista de blocos CIDR para as sub-redes privadas."
  type        = list(string)
}

variable "instance_types" {
  description = "Lista de tipos de instância para o grupo de nós gerenciado do EKS."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Número desejado de nós no grupo de nós gerenciado do EKS."
  type        = number
}

variable "max_size" {
  description = "Número máximo de nós no grupo de nós gerenciado do EKS."
  type        = number
}

variable "min_size" {
  description = "Número mínimo de nós no grupo de nós gerenciado do EKS."
  type        = number
}