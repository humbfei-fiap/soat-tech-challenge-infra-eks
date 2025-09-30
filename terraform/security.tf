resource "aws_security_group_rule" "allow_postgres_egress" {
  description       = "Allow EKS nodes to connect to the PostgreSQL database."
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # ATENÇÃO: Idealmente, restrinja para o IP ou Security Group do seu banco de dados.

  security_group_id = module.eks.node_security_group_id
}
