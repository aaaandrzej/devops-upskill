resource "aws_lb_target_group" "db_apps" {
  name     = "db-lb-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  tags = {
    Name  = "${var.owner}-db-lb-tg"
    Owner = var.owner
  }
}

resource "aws_lb_target_group" "external" {
  name     = "external-lb-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  tags = {
    Name  = "${var.owner}-external-lb-tg"
    Owner = var.owner
  }
}

resource "aws_lb_target_group_attachment" "db_apps" {
  count            = local.az_count
  target_group_arn = aws_lb_target_group.db_apps.arn
  target_id        = aws_instance.db_app[count.index].id
  port             = 8000
}

resource "aws_lb_target_group_attachment" "external" {
  count            = local.az_count
  target_group_arn = aws_lb_target_group.external.arn
  target_id        = aws_instance.s3_app[count.index].id
  port             = 8000
}

resource "aws_lb" "db_apps" {
  name               = "db-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.db_lb.id]
  subnets            = aws_subnet.private_subnets[*].id
  tags = {
    Name  = "${var.owner}-db-lb"
    Owner = var.owner
  }
}

resource "aws_lb" "external" {
  name               = "external-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.external_lb.id]
  subnets            = aws_subnet.public_subnets[*].id
  tags = {
    Name  = "${var.owner}-external-lb"
    Owner = var.owner
  }
}

resource "aws_lb_listener" "db_apps" {
  load_balancer_arn = aws_lb.db_apps.arn
  port              = "8000"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db_apps.arn
  }
  tags = {
    Name  = "${var.owner}-db-lb-listener"
    Owner = var.owner
  }
}

resource "aws_lb_listener" "external" {
  load_balancer_arn = aws_lb.external.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external.arn
  }
  tags = {
    Name  = "${var.owner}-external-lb-listener"
    Owner = var.owner
  }
}