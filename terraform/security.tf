resource "aws_security_group_rule" "allow_postgres_egress" {
  description       = "Allow EKS nodes to connect to the PostgreSQL database."
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
    # [!! AVISO DE SEGURANÇA !!]
  # A regra abaixo permite que os nós do EKS se conectem a QUALQUER IP na porta 5432.
  # Isso é aceitável para desenvolvimento inicial, mas INSEGURO para produção.
  # ASSIM QUE O RDS FOR CRIADO, SUBSTITUA 'cidr_blocks' PELA LINHA ABAIXO:
  # source_security_group_id = <ID_DO_SECURITY_GROUP_DO_SEU_RDS>
  cidr_blocks       = ["0.0.0.0/0"]

  security_group_id = module.eks.node_security_group_id
}
