output "vpc_id" {
  value = length(aws_vpc.main) > 0 ? aws_vpc.main[0].id : null
}

output "subnets_ids" {
  value = [for k, v in aws_subnet.subnets : v.id]
}

output "aws_db_subnet_group_name" {
  value = length(aws_db_subnet_group.default) > 0 ? aws_db_subnet_group.default[0].name : null
}

output "db_app_sg_id" {
  value = length(aws_security_group.db_app) > 0 ? aws_security_group.db_app[0].id : 0
}

output "db_sg_id" {
  value = length(aws_security_group.db) > 0 ? aws_security_group.db[0].id : null
}

output "db_lb_sg_id" {
  value = length(aws_security_group.db_lb) > 0 ? aws_security_group.db_lb[0].id : null
}

output "s3_app_sg_id" {
  value = length(aws_security_group.s3_app) > 0 ? aws_security_group.s3_app[0].id : null
}

output "ext_lb_sg_id" {
  value = length(aws_security_group.external_lb) > 0 ? aws_security_group.external_lb[0].id : null
}

output "public_sg_id" {
  value = length(aws_security_group.public) > 0 ? aws_security_group.public[0].id : null
}