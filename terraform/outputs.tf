output "bastion_ip_address" {
  value       = aws_instance.bastion.public_ip
  description = "The IP address of the bastion"
}

output "db_apps_ip_addresses" {
  value       = aws_instance.db_app[*].private_ip
  description = "The IP addresses of the db apps"
}

output "s3_apps_ip_addresses" {
  value       = aws_instance.s3_app[*].private_ip
  description = "The IP addresses of the s3 apps"
}

output "bucket-name" {
  value       = aws_s3_bucket.main.id
  description = "The name of the bucket"
}