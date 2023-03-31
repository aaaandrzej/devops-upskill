resource "aws_lb_target_group" "db_apps" {
  name     = "db-lb-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags = {
    Name  = "${var.owner}-db-lb-tg"
    Owner = var.owner
  }
}

resource "aws_lb_target_group" "external" {
  name     = "external-lb-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags = {
    Name  = "${var.owner}-external-lb-tg"
    Owner = var.owner
  }
}

resource "aws_lb" "db_apps" {
  name               = "db-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.db_lb_sg]
  subnets            = var.private_subnets
  tags = {
    Name  = "${var.owner}-db-lb"
    Owner = var.owner
  }
}

resource "aws_lb" "external" {
  name               = "external-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.external_lb_sg]
  subnets            = var.public_subnets
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