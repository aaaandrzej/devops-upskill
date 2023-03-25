output "bastion_public_ip" {
  value = aws_instance.bastion[*].public_ip
}

output "db_apps_ids" {
  value = aws_instance.db_app[*].id
}