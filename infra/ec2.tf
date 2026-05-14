resource "aws_instance" "frontend" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = "t2.micro"
  key_name               = "spa-key"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io git nginx
    systemctl start docker
    systemctl enable docker
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = {
    Name = "innova-frontend"
    Role = "Frontend"
  }
}

resource "aws_launch_template" "backend_lt" {
  name          = "innova-backend-lt"
  image_id      = "ami-0ec10929233384c7f"
  instance_type = "t2.micro"
  key_name      = "spa-key"

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io git openjdk-17-jdk
    systemctl start docker
    systemctl enable docker
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "innova-backend"
      Role = "Backend"
    }
  }
}

resource "aws_instance" "backend" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = "t2.micro"
  key_name               = "spa-key"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  depends_on = [aws_nat_gateway.nat]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io git openjdk-17-jdk
    systemctl start docker
    systemctl enable docker
  EOF

  tags = {
    Name = "innova-backend"
    Role = "Backend"
  }
}

resource "aws_instance" "data" {
  ami                    = "ami-0ec10929233384c7f"
  instance_type          = "t2.micro"
  key_name               = "spa-key"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.data_sg.id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name

  depends_on = [aws_nat_gateway.nat]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y mysql-server docker.io git
    systemctl start mysql
    systemctl enable mysql
    systemctl start docker
    systemctl enable docker
  EOF

  tags = {
    Name = "innova-data"
    Role = "Database"
  }
}