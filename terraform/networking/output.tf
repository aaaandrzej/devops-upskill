output "vpc_id" {
  value = aws_vpc.main.id
}

output "az_count" {
  value = local.az_count
}

output "private_subnets_ids" {
  value = [for k, v in aws_subnet.private_subnets : v.id]
}

output "public_subnets_ids" {
  value = [for k, v in aws_subnet.public_subnets : v.id]
}

output "aws_db_subnet_group_name" {
  value = aws_db_subnet_group.default.name
}

output "db_app_sg_id" {
  value = aws_security_group.db_app.id
}

output "db_sg_id" {
  value = aws_security_group.db.id
}

output "db_lb_sg_id" {
  value = aws_security_group.db_lb.id
}

output "s3_app_sg_id" {
  value = aws_security_group.s3_app.id
}

output "ext_lb_sg_id" {
  value = aws_security_group.external_lb.id
}

output "public_sg_id" {
  value = aws_security_group.public.id
}