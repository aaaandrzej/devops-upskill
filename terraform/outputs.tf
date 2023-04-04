output "bastions_ip_addresses" {
  value       = aws_instance.bastion[*].public_ip
  description = "The IP addresses of the bastions"
}

output "bucket-name" {
  value       = module.storage.bucket_name
  description = "The name of the bucket"
}

output "external-lb-address" {
  value       = "http://${module.loadbalancing-external.dns_name}/"
  description = "The address of external load balancer"
}