resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.nombre_proyecto}"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "main" {
  name = "${var.nombre_proyecto}-cluster"
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
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.frontend_sg.id]
    assign_public_ip = true
  }
}