terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "wisecow_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "wisecow-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "wisecow_igw" {
  vpc_id = aws_vpc.wisecow_vpc.id

  tags = {
    Name = "wisecow-igw"
  }
}

# Public Subnets
resource "aws_subnet" "wisecow_public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.wisecow_vpc.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "wisecow-public-subnet-${count.index + 1}"
  }
}

# Route Table
resource "aws_route_table" "wisecow_public_rt" {
  vpc_id = aws_vpc.wisecow_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wisecow_igw.id
  }

  tags = {
    Name = "wisecow-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "wisecow_public_rta" {
  count          = 2
  subnet_id      = aws_subnet.wisecow_public_subnet[count.index].id
  route_table_id = aws_route_table.wisecow_public_rt.id
}

# Security Group for EKS
resource "aws_security_group" "wisecow_eks_sg" {
  name        = "wisecow-eks-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.wisecow_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wisecow-eks-sg"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "wisecow_cluster" {
  name     = "wisecow-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.wisecow_public_subnet[*].id
    security_group_ids = [aws_security_group.wisecow_eks_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "wisecow_nodes" {
  cluster_name    = aws_eks_cluster.wisecow_cluster.name
  node_group_name = "wisecow-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.wisecow_public_subnet[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
