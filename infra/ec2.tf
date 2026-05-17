resource "aws_cloudwatch_log_group" "ec2" {
  name              = "/ec2/${var.nombre_proyecto}"
  retention_in_days = 7
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.data_sg.id]
  key_name               = var.key_pair_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl start docker
    systemctl enable docker

    until docker info > /dev/null 2>&1; do
      echo "Esperando Docker..."
      sleep 3
    done

    docker system prune -af

    docker run -d \
      --name mysql \
      -e MYSQL_ROOT_PASSWORD=root \
      -e MYSQL_DATABASE=innovatech_db \
      -e MYSQL_ROOT_HOST=% \
      -p 3306:3306 \
      --restart always \
      mysql:8.0 \
      --bind-address=0.0.0.0
  EOF

  tags = {
    Name = "${var.nombre_proyecto}-mysql"
    Role = "Database"
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = var.key_pair_name

  depends_on = [aws_nat_gateway.nat]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker aws-cli
    systemctl start docker
    systemctl enable docker
    
    docker pull ${aws_ecr_repository.backend.repository_url}:latest
    docker run -d \
      --name backend \
      -p 8080:8080 \
      -e DB_HOST=${aws_instance.db.private_ip} \
      -e DB_PORT=3306 \
      -e DB_NAME=innovatech_db \
      -e DB_USERNAME=root \
      -e DB_PASSWORD=root \
      --restart always \
      ${aws_ecr_repository.backend.repository_url}:latest
  EOF

  tags = {
    Name = "${var.nombre_proyecto}-backend"
    Role = "Backend"
  }
}

resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  key_name               = var.key_pair_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker aws-cli
    systemctl start docker
    systemctl enable docker

    docker pull ${aws_ecr_repository.frontend.repository_url}:latest
    docker run -d \
      --name frontend \
      -p 80:80 \
      --restart always \
      ${aws_ecr_repository.frontend.repository_url}:latest
  EOF

  tags = {
    Name = "${var.nombre_proyecto}-frontend"
    Role = "Frontend"
  }
}