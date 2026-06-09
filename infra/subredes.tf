resource "aws_subnet" "eks_subnet_1" {
  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-1"
  }
}

resource "aws_subnet" "eks_subnet_2" {
  vpc_id = aws_vpc.eks_vpc.id
  cidr_block = "10.0.20.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-2"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "eks-route-table"
  }
}

resource "aws_route_table_association" "rt_1" {
  subnet_id = aws_subnet.eks_subnet_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rt_2" {
  subnet_id = aws_subnet.eks_subnet_2.id
  route_table_id = aws_route_table.rt.id
}
