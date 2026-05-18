data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-*-x86_64"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.nombre_proyecto}-cluster"
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.nombre_proyecto}-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t2.micro"
  key_name      = var.key_pair_name

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
  )
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.nombre_proyecto}-ecs-asg"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier = [aws_subnet.public.id]

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "main" {
  name = "${var.nombre_proyecto}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
    base              = 1
  }
}

resource "aws_cloudwatch_log_group" "ecs_frontend" {
  name              = "/ecs/${var.nombre_proyecto}-frontend"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.nombre_proyecto}-frontend"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.aws_iam_role.lab.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:latest"
      essential = true
      memory    = 256
      cpu       = 256

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.nombre_proyecto}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
    base              = 1
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]
}

resource "aws_ecr_repository" "backend_despacho" {
  name         = "${var.nombre_proyecto}-backend-despacho"
  force_delete = true
}

resource "aws_cloudwatch_log_group" "ecs_backend_ventas" {
  name              = "/ecs/${var.nombre_proyecto}-backend-ventas"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_backend_despacho" {
  name              = "/ecs/${var.nombre_proyecto}-backend-despacho"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "backend_ventas" {
  family                   = "${var.nombre_proyecto}-backend-ventas"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.aws_iam_role.lab.arn

  container_definitions = jsonencode([
    {
      name      = "backend-ventas"
      image     = "${aws_ecr_repository.backend.repository_url}:latest"
      essential = true
      memory    = 256
      cpu       = 256

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DB_HOST",     value = aws_instance.db.private_ip },
        { name = "DB_PORT",     value = "3306" },
        { name = "DB_NAME",     value = var.db_name },
        { name = "DB_USERNAME", value = var.db_user },
        { name = "DB_PASSWORD", value = var.db_password }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_backend_ventas.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend-ventas"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "backend_despacho" {
  family                   = "${var.nombre_proyecto}-backend-despacho"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.aws_iam_role.lab.arn

  container_definitions = jsonencode([
    {
      name      = "backend-despacho"
      image     = "${aws_ecr_repository.backend_despacho.repository_url}:latest"
      essential = true
      memory    = 256
      cpu       = 256

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 9090
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DB_HOST",     value = aws_instance.db.private_ip },
        { name = "DB_PORT",     value = "3306" },
        { name = "DB_NAME",     value = var.db_name },
        { name = "DB_USERNAME", value = var.db_user },
        { name = "DB_PASSWORD", value = var.db_password }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_backend_despacho.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend-despacho"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "backend_ventas" {
  name            = "${var.nombre_proyecto}-backend-ventas-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend_ventas.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
    base              = 0
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]
}

resource "aws_ecs_service" "backend_despacho" {
  name            = "${var.nombre_proyecto}-backend-despacho-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend_despacho.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
    base              = 0
  }

  depends_on = [aws_ecs_cluster_capacity_providers.main]
}
