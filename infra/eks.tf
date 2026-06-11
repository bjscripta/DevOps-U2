resource "aws_eks_cluster" "eks" {
  name = "${var.nombre_proyecto}"
  role_arn = data.aws_iam_role.labrole.arn
  vpc_config {
    subnet_ids = [aws_subnet.eks_subnet_1.id,
                aws_subnet.eks_subnet_2.id]
  } 
}

resource "aws_eks_node_group" "workers" {
  cluster_name = aws_eks_cluster.eks.name
  node_group_name = "workers"
  node_role_arn = data.aws_iam_role.labrole.arn
  subnet_ids = [aws_subnet.eks_subnet_1.id,
                aws_subnet.eks_subnet_2.id]
  scaling_config {
    desired_size = 2
    max_size = 3
    min_size = 2
  }
  instance_types = ["t2.micro"]
  capacity_type = "ON_DEMAND"
}