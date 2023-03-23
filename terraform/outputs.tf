output "bastion_ip_address" {
  value       = aws_instance.bastion.public_ip
  description = "The IP address of the bastion"
}

output "bucket-name" {
  value       = aws_s3_bucket.main.id
  description = "The name of the bucket"
}

output "external-lb-address" {
  value       = "http://${aws_lb.external.dns_name}/"
  description = "The address of external load balancer"
}