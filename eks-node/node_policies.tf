resource "aws_security_group" "node_ssh" {
  name  = "${var.cluster.name}_${var.node_name}_node_ssh"
  description = "Allows ssh access from an specific instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["10.6.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.cluster.name}_${var.node_name}_node_ssh"
  }
}

resource "aws_security_group" "node_efs" {
  name  = "${var.cluster.name}_${var.node_name}_node_efs"
  description = "Allows efs mount from anywhere in vpc"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    cidr_blocks = ["10.6.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.cluster.name}_${var.node_name}_node_efs"
  }
}

resource "aws_iam_role" "node_role" {
  name = "${var.cluster.name}_${var.node_name}_nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:AssumeRoleWithWebIdentity"
      ]
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node_eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_eks_alb" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_eks_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}
resource "aws_iam_role_policy_attachment" "node_eks_waf" {
  policy_arn = "arn:aws:iam::aws:policy/AWSWAFFullAccess"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_eks_vpc" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_eks_efs" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_eks_autoscaling" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_instance_profile" "worker_nodes" {
  name = "${var.cluster.name}_${var.node_name}_worker_nodes"
  role = aws_iam_role.node_role.name
}
