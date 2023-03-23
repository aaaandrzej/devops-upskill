resource "aws_instance" "bastion" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_size
  subnet_id       = aws_subnet.public_subnets[0].id
  security_groups = [aws_security_group.public.id]
  key_name        = aws_key_pair.kp.id
  tags = {
    Name  = "${var.owner}-bastion"
    Owner = var.owner
  }
}

resource "aws_instance" "db_app" {
  depends_on      = [aws_db_instance.default]
  count           = local.az_count
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_size
  subnet_id       = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.db_app.id]
  key_name        = aws_key_pair.kp.id
  user_data = templatefile(
    "${path.module}/userdata/db_app_userdata.sh.tftpl",
    {
      db_host     = aws_db_instance.default.address
      db_port     = aws_db_instance.default.port
      db_user     = var.db_user
      db_password = var.db_password
      db_name     = var.db_name
    }
  )

  tags = {
    Name  = join("-", [var.owner, "db-app", ["a", "b"][count.index]])
    Owner = var.owner
  }
}
