# Secrets Module - AWS Secrets Manager

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}-${var.environment}/db-credentials"

  tags = {
    Name = "${var.project_name}-${var.environment}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = 5432
    dbname   = var.db_name
  })
}

resource "aws_secretsmanager_secret" "app_secrets" {
  name = "${var.project_name}-${var.environment}/app-secrets"

  tags = {
    Name = "${var.project_name}-${var.environment}-app-secrets"
  }
}
