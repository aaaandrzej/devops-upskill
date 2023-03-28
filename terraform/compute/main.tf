data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_template" "s3_app" {
  name                   = "s3_app_lt"
  image_id               = data.aws_ami.ubuntu.id
  key_name               = var.key_name
  instance_type          = var.instance_size
  vpc_security_group_ids = [var.s3_app_sg]

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  user_data = var.s3_app_user_data

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name  = "${var.owner}-s3-app-instance"
      Owner = var.owner
    }
  }
  tags = {
    Name  = "${var.owner}-s3-app-lt"
    Owner = var.owner
  }
}

resource "aws_autoscaling_group" "main" {
  vpc_zone_identifier = var.private_subnets
  target_group_arns   = [var.s3_tg_arn]
  desired_capacity    = var.no_of_s3_apps[1]
  max_size            = var.no_of_s3_apps[2]
  min_size            = var.no_of_s3_apps[0]

  launch_template {
    id      = aws_launch_template.s3_app.id
    version = "$Latest"
  }
}

resource "aws_instance" "db_app" {
  depends_on      = [var.db_app_dependency]
  count           = var.no_of_db_apps
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_size
  subnet_id       = var.private_subnets[count.index]
  security_groups = [var.db_app_sg]
  key_name        = var.key_name
  user_data       = var.db_app_user_data

  tags = {
    Name  = join("-", [var.owner, "db-app", (count.index + 1)])
    Owner = var.owner
  }
}


resource "aws_instance" "bastion" {
  count           = var.no_of_bastions
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_size
  subnet_id       = var.public_subnets[count.index]
  security_groups = [var.bastion_sg]
  key_name        = var.key_name
  tags = {
    Name  = join("-", [var.owner, "bastion", (count.index + 1)])
    Owner = var.owner
  }
}