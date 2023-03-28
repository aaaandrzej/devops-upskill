output "bastions_ip_addresses" {
  value       = module.compute.bastion_public_ip
  description = "The IP addresses of the bastions"
}

output "bucket-name" {
  value       = module.storage.bucket_name
  description = "The name of the bucket"
}

output "external-lb-address" {
  value       = "http://${module.loadbalancing.external_lb_dns_name}/"
  description = "The address of external load balancer"
}