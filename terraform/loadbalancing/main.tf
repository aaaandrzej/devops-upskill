resource "aws_lb_target_group" "main" {
  name     = "${var.name}-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags = {
    Name  = "${var.owner}-${var.name}-tg"
    Owner = var.owner
  }
}

resource "aws_lb" "main" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [var.security_group]
  subnets            = var.subnets
  tags = {
    Name  = "${var.owner}-${var.name}"
    Owner = var.owner
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
  tags = {
    Name  = "${var.owner}-${var.name}-listener"
    Owner = var.owner
  }
}
