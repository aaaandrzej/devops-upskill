resource "aws_db_instance" "default" {
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  parameter_group_name   = "default.mysql5.7"
  allocated_storage      = 10
  skip_final_snapshot    = true
  publicly_accessible    = false
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  tags = {
    Name  = "${var.owner}-db"
    Owner = var.owner
  }
}