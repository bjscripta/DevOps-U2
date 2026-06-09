resource "aws_ecr_repository" "backend" {
  name         = "${var.nombre_proyecto}-backend"
    image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
  tags = {
    Name = "${var.nombre_proyecto}-backend"
  }
}

resource "aws_ecr_repository" "frontend" {
  name         = "${var.nombre_proyecto}-frontend"
    image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
  tags = {
    Name = "${var.nombre_proyecto}-frontend"
  }
}