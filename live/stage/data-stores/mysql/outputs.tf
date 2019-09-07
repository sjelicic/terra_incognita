output "secret" {
  value = data.aws_secretsmanager_secret_version.db_password.secret_string
  description = "secrets manager"
}

output "address" {
  value = aws_db_instance.db_example.address
  description = "database endpoint"
}

output "port" {
  value = aws_db_instance.db_example.port
  description = "the port database is listening on"
}