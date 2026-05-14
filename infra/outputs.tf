output "frontend_public_ip" {
  description = "IP pública del frontend"
  value       = aws_instance.frontend.public_ip
}

output "backend_private_ip" {
  description = "IP privada del backend"
  value       = aws_instance.backend.private_ip
}

output "data_private_ip" {
  description = "IP privada de la instancia MySQL"
  value       = aws_instance.data.private_ip
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "frontend_sg_id" {
  description = "ID del Security Group Frontend"
  value       = aws_security_group.frontend_sg.id
}

# URLs de ECR (si los creas)
# output "ecr_frontend_url" {
#   value = aws_ecr_repository.frontend.repository_url
# }