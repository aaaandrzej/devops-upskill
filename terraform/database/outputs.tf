output "db_address" {
  value = aws_db_instance.default.address
}

output "db_port" {
  value = aws_db_instance.default.port
}

output "db" {
  value = aws_db_instance.default
}