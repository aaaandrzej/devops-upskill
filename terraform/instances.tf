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
  count           = local.az_count
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_size
  subnet_id       = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.db_app.id]
  key_name        = aws_key_pair.kp.id
  user_data = templatefile(
    "${path.module}/userdata/db_app_userdata.sh.tftpl",
    {
      db_host     = "0.0.0.0" # TODO temp ip, replace with rds ip
      db_port     = var.db_port
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

resource "aws_instance" "s3_app" {
  count           = local.az_count
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_size
  subnet_id       = aws_subnet.private_subnets[count.index].id
  security_groups = [aws_security_group.s3_app.id]
  key_name        = aws_key_pair.kp.id
  #  iam_instance_profile = ""  # TODO
  user_data = templatefile(
    "${path.module}/userdata/s3_app_userdata.sh.tftpl",
    {
      db_app_host    = aws_instance.db_app[0].private_ip # TODO temp, replace with db app alb
      s3_bucket_name = aws_s3_bucket.main.id
    }
  )

  tags = {
    Name  = join("-", [var.owner, "s3-app", ["a", "b"][count.index]])
    Owner = var.owner
  }
}