output "cluster-name" {
  value = aws_eks_cluster.eks.name
}

output "cluster-endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "backend-ecr-url" {
  value = aws_ecr_repository.backend
}

output "frontend-ecr-url" {
  value = aws_ecr_repository.frontend
}