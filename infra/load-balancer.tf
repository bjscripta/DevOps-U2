resource "aws_lb" "frontend_alb" {
  name               = "${var.nombre_proyecto}-frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]
  tags = {
    Name = "${var.nombre_proyecto}-frontend-alb"
  }
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.nombre_proyecto}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.eks_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
  }

  tags = {
    Name = "${var.nombre_proyecto}-frontend-tg"
  }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}
