############################
# TODO MALO ECS
############################

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.nombre_proyecto}"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "main" {
  name = "${var.nombre_proyecto}-cluster"
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.nombre_proyecto}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.nombre_proyecto}-alb-sg"
  }
}

resource "aws_lb" "main" {
  name               = "${var.nombre_proyecto}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]

  tags = {
    Name = "${var.nombre_proyecto}-alb"
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.nombre_proyecto}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
  }

  tags = {
    Name = "${var.nombre_proyecto}-tg"
  }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.nombre_proyecto}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = data.aws_iam_role.lab.arn

  container_definitions = jsonencode([

    {
      name  = "backend"
      image = "${aws_ecr_repository.backend.repository_url}:latest"

      portMappings = [
        {
          containerPort = 8080
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      environment = [
        {
          name  = "DB_HOST",
          value = aws_instance.db.private_ip
        },
        {
          name  = "DB_PORT",
          value = "3306"
        },
        {
          name  = "DB_NAME",
          value = "innovatech_db"
        },
        {
          name  = "DB_USERNAME",
          value = "root"
        },
        {
          name  = "DB_PASSWORD",
          value = "root"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
        }
      }
    },

    {
      name  = "frontend"
      image = "${aws_ecr_repository.frontend.repository_url}:latest"

      portMappings = [
        {
          containerPort = 80
        }
      ]

      dependsOn = [
        {
          containerName = "backend"
          condition     = "START"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "frontend"
        }
      }
    }

  ])
}

resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  force_new_deployment = true

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    subnets          = [aws_subnet.public.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.backend_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.frontend]
}

output "alb_dns_name" {
  description = "DNS name del Load Balancer"
  value       = aws_lb.main.dns_name
}

