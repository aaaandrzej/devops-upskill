resource "aws_launch_template" "s3_app" {
  name = "s3_app_lt"

  image_id               = data.aws_ami.ubuntu.id
  key_name               = aws_key_pair.kp.id
  instance_type          = var.instance_size
  vpc_security_group_ids = [aws_security_group.s3_app.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  user_data = base64encode(
    templatefile(
      "${path.module}/userdata/s3_app_userdata.sh.tftpl",
      {
        db_app_host    = aws_lb.db_apps.dns_name
        s3_bucket_name = aws_s3_bucket.main.id
      }
    )
  )

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
  vpc_zone_identifier = aws_subnet.private_subnets[*].id
  target_group_arns   = [aws_lb_target_group.external.arn]
  desired_capacity    = 4
  max_size            = 6
  min_size            = 2

  launch_template {
    id      = aws_launch_template.s3_app.id
    version = "$Latest"
  }
}