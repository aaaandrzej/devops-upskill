output "external_lb_dns_name" {
  value = aws_lb.external.dns_name
}

output "s3_tg_arn" {
  value = aws_lb_target_group.external.arn
}
output "db_lb_host" {
  value = aws_lb.db_apps.dns_name
}