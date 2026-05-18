resource "aws_ecr_repository" "backend" {
  name         = "${var.nombre_proyecto}-backend"
  force_delete = true
}

resource "aws_ecr_repository" "frontend" {
  name         = "${var.nombre_proyecto}-frontend"
  force_delete = true
}