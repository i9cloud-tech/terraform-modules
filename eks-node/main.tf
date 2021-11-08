data "aws_ssm_parameter" "ami" {
  name = "/aws/service/eks/optimized-ami/1.20/amazon-linux-2/recommended/image_id"
}

locals {
  node = templatefile("${path.module}/userdata.tpl", {
    node_group_name = "${var.node_name}_node",
    label           = var.node_name
    cluster_ca      = var.cluster.certificate_authority[0].data
    api_url         = var.cluster.endpoint
    instance_type   = data.aws_ssm_parameter.ami.value
    efs             = aws_efs_file_system.node_efs.dns_name
  })
}

resource "aws_efs_file_system" "node_efs" {
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.cluster_name}_${var.node_name}_nodes"
  }
}

resource "aws_efs_mount_target" "node_subnet1" {
  file_system_id  = aws_efs_file_system.node_efs.id
  subnet_id       = var.public_subnet_ids[0]
  security_groups = [aws_security_group.node_efs.id]
}

resource "aws_efs_mount_target" "node_subnet2" {
  file_system_id = aws_efs_file_system.node_efs.id
  subnet_id      = var.public_subnet_ids[1]
  security_groups = [aws_security_group.node_efs.id]
}

resource "aws_efs_access_point" "node_ap" {
  file_system_id = aws_efs_file_system.node_efs.id
}

resource "aws_security_group" "node_ssh" {
  name  = "${var.node_name}_node_ssh"
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
    Name = "${var.node_name}_node_ssh"
  }
}

resource "aws_security_group" "node_efs" {
  name  = "${var.node_name}_node_efs"
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
    Name = "${var.node_name}_node_efs"
  }
}

resource "aws_iam_role" "node_role" {
  name = "${var.cluster_name}_${var.node_name}_nodes"

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
  policy_arn = "arn:aws:iam::aws:policy/AWSWAFConsoleReadOnlyAccess"
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
  name = "${var.node_name}_worker_nodes"
  role = aws_iam_role.node_role.name
}

resource "aws_launch_template" "node_template" {
  name_prefix            = "${var.cluster_name}_${var.node_name}_nodes"
  image_id               = data.aws_ssm_parameter.ami.value
  instance_type          = var.instance_types[0]
  user_data              = base64encode(local.node)
  vpc_security_group_ids = [
    aws_security_group.node_ssh.id,
    var.cluster.vpc_config[0].cluster_security_group_id
  ]
  key_name               = "k8s_key"
  iam_instance_profile {
    arn = aws_iam_instance_profile.worker_nodes.arn
  }

  tags = {
    Name = "k8s_${var.node_name}_nodes"
    "k8s.io/cluster-autoscaler/aws_eks_cluster.cluster.name" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "kubernetes.io/cluster/cluster"  = "owned"
  }
}

resource "aws_autoscaling_group" "node_asg" {
  vpc_zone_identifier= concat(var.public_subnet_ids, var.private_subnet_ids)
  desired_capacity   = var.autoscale_configs.desired_capacity
  min_size           = var.autoscale_configs.min_size
  max_size           = var.autoscale_configs.max_size
  name               = "k8s_${var.node_name}_nodes"
  enabled_metrics    = [
    "GroupAndWarmPoolDesiredCapacity", "GroupAndWarmPoolTotalCapacity", "GroupDesiredCapacity",
    "GroupInServiceCapacity",          "GroupInServiceInstances",       "GroupMaxSize",
    "GroupMinSize",                    "GroupPendingCapacity",          "GroupPendingInstances",
    "GroupStandbyCapacity",            "GroupStandbyInstances",         "GroupTerminatingCapacity",
    "GroupTerminatingInstances",       "GroupTotalCapacity",            "GroupTotalInstances",
    "WarmPoolDesiredCapacity",         "WarmPoolMinSize",               "WarmPoolPendingCapacity",
    "WarmPoolTerminatingCapacity",     "WarmPoolTotalCapacity",         "WarmPoolWarmedCapacity",
  ]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.autoscale_configs.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = var.autoscale_configs.on_demand_percentage_capacity
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.node_template.id
        version = "$Latest"
      }

      dynamic "override" {
        for_each = toset(var.instance_types)

        override {
          instance_type = override.value
        }
      }
    }
  }

  tags = concat([{
    key   = "Name"
    value = "k8s_${node_name}_nodes"
    propagate_at_launch = "true"
  }, {
    key   = "k8s.io/cluster-autoscaler/aws_eks_cluster.cluster.name"
    value ="owned"
    propagate_at_launch = "true"
  }, {
    key   = "k8s.io/cluster-autoscaler/enabled"
    value ="true"
    propagate_at_launch = "true"
  }, {
    key   = "kubernetes.io/cluster/cluster"
    value = "owned"
    propagate_at_launch = "true"
  }])

  depends_on = [
    aws_iam_role_policy_attachment.node_eks_worker,
    aws_iam_role_policy_attachment.node_eks_cni,
    aws_iam_role_policy_attachment.node_eks_ecr,
    aws_iam_role_policy_attachment.node_eks_waf,
    aws_iam_role_policy_attachment.node_eks_alb,
    aws_iam_role_policy_attachment.node_eks_vpc,
  ]

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
