resource "aws_launch_template" "main" {
  name                   = "${var.app_name}-lt"
  image_id               = var.image_id
  key_name               = var.key_name
  instance_type          = var.instance_size
  vpc_security_group_ids = [var.app_sg]

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  user_data = var.user_data

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name  = "${var.owner}-${var.app_name}-instance"
      Owner = var.owner
    }
  }
  tags = {
    Name  = "${var.owner}-${var.app_name}-lt"
    Owner = var.owner
  }
}

resource "aws_autoscaling_group" "main" {
  depends_on          = [var.app_dependency]
  vpc_zone_identifier = var.subnets
  target_group_arns   = [var.tg_arn]
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
}
