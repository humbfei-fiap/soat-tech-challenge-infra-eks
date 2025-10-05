
# Este arquivo descreve os recursos de backend que você já criou manualmente.
# Usaremos isso para importá-los para o gerenciamento do Terraform.

resource "aws_s3_bucket" "state" {
  # O nome do bucket deve ser exatamente o mesmo que você criou.
  bucket = "meu-eks-terraform-state"
}

resource "aws_dynamodb_table" "lock" {
  # O nome da tabela deve ser exatamente o mesmo que você criou.
  name     = "meu-eks-terraform-lock-001"
  hash_key = "LockID"

  # O restante dos atributos deve corresponder à configuração da sua tabela.
  # Se você não definiu capacidade de leitura/escrita, o modo PAY_PER_REQUEST é o padrão.
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}
