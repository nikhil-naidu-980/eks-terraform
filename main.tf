  provider "aws" {
    region = "us-west-2"
  }

  # Create the VPC
  resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
  }

  # Create the public subnet
  resource "aws_subnet" "public" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "us-west-2a"
    map_public_ip_on_launch = true
    tags = {
      Name = "Public Subnet"
    }
  }

  # Create the private subnet
  resource "aws_subnet" "private" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-west-2b"
    tags = {
      Name = "Private Subnet"
    }
  }

  # Create the Internet Gateway
  resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = {
      Name = "Internet Gateway"
    }
  }

  # Route for public subnet to use internet
  resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
  }

  resource "aws_route" "public_internet" {
    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.main.id
  }

  resource "aws_route_table_association" "public" {
    subnet_id      = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
  }

  # Create the Security Group

  resource "aws_security_group" "eks" {
    name        = "eks-security-group"
    description = "Allow access to EKS cluster"
    vpc_id      = aws_vpc.main.id
  }
    
  resource "aws_security_group_rule" "allow_ingress" {
    type        = "ingress"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.eks.id
  }

  # IAM Role for EKS Cluster
  resource "aws_iam_role" "eks_cluster_role" {
    name = "eks-cluster-role"
    
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }]
    })
  }
    
  # Attach policy for EKS Cluster management
  resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
    role       = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  }
    
  # Attach policy for VPC management (needed by EKS to configure networking)
  resource "aws_iam_role_policy_attachment" "eks_vpc_policy_attachment" {
    role       = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  }

  # IAM Role for EKS Worker Nodes
  resource "aws_iam_role" "eks_node_role" {
    name = "eks-node-role"

    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }]
    })
  }
    
  # Attach policies for EKS worker nodes
  resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
    role       = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  }
    
  resource "aws_iam_role_policy_attachment" "ec2_container_registry" {
    role       = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }
    
  resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
    role       = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }
    
  resource "aws_iam_role_policy_attachment" "autoscaling" {
    role       = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  }
    
  resource "aws_iam_role_policy_attachment" "ec2_full" {
    role       = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  }

  resource "aws_eks_cluster" "main" {
    name     = "my-eks-cluster"
    role_arn = aws_iam_role.eks_cluster_role.arn
  
    vpc_config {
      subnet_ids = [aws_subnet.public.id, aws_subnet.private.id]
      security_group_ids = [aws_security_group.eks.id]
    }
  }
    
  resource "aws_eks_node_group" "main" {
    depends_on = [aws_eks_cluster.main]
    cluster_name    = aws_eks_cluster.main.name
    node_group_name = "my-node-group"
    node_role_arn   = aws_iam_role.eks_node_role.arn
    subnet_ids      = [aws_subnet.public.id]

    scaling_config {
      min_size = 1
      desired_size = 1
      max_size = 3
    }
  }