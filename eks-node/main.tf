data "aws_ssm_parameter" "ami" {
  name = "/aws/service/eks/optimized-ami/${var.instance_version}/amazon-linux-2/recommended/image_id"
}

locals {
  node = templatefile("${path.module}/userdata.tpl", {
    node_group_name = "${var.node_name}-node",
    label_value     = coalesce(var.node_label_value, var.node_name)
    label_key       = var.node_label_key
    cluster_ca      = var.cluster.ca
    cluster_name    = var.cluster.name
    api_url         = var.cluster.endpoint
    instance_type   = data.aws_ssm_parameter.ami.value
    efs             = aws_efs_file_system.node_efs.id
  })
}

resource "aws_efs_file_system" "node_efs" {
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.cluster.name}-${var.node_name}-nodes"
  }
}

resource "aws_efs_mount_target" "subnets" {
  file_system_id  = aws_efs_file_system.node_efs.id
  count           = length(var.private_subnets)
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.node_efs.id]
}

resource "aws_efs_access_point" "node_ap" {
  file_system_id = aws_efs_file_system.node_efs.id
}

resource "aws_launch_template" "node_template" {
  name_prefix            = "${var.cluster.name}-${var.node_name}-nodes"
  image_id               = data.aws_ssm_parameter.ami.value
  instance_type          = var.instance_types[0]
  user_data              = base64encode(local.node)
  vpc_security_group_ids = [
    aws_security_group.node_ssh.id,
    var.cluster.sg_id
  ]
  key_name               = var.ssh_key_name
  iam_instance_profile {
    arn = aws_iam_instance_profile.worker_nodes.arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 40
      delete_on_termination = true
    }
  }

  tags = {
    Name = "${var.cluster.name}-${var.node_name}-nodes"
    "k8s.io/cluster-autoscaler/aws_eks_cluster.cluster.name" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                      = "true"
    "kubernetes.io/cluster/cluster"                          = "owned"
  }
}

resource "aws_autoscaling_group" "node_asg" {
  vpc_zone_identifier = concat(var.private_subnets, var.public_subnets)
  desired_capacity    = var.autoscale_configs.desired_capacity
  min_size            = var.autoscale_configs.min_size
  max_size            = var.autoscale_configs.max_size
  name                = "${var.cluster.name}-${var.node_name}-nodes"
  enabled_metrics     = [
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

        content {
          instance_type = override.value
        }
      }
    }
  }

  tag {
    key   = "Name"
    value = "${var.cluster.name}-${var.node_name}-nodes"
    propagate_at_launch = "true"
  }
  tag {
    key   = "k8s.io/cluster-autoscaler/aws_eks_cluster.cluster.name"
    value ="owned"
    propagate_at_launch = "true"
  }
  tag {
    key   = "k8s.io/cluster-autoscaler/enabled"
    value ="true"
    propagate_at_launch = "true"
  }
  tag {
    key   = "kubernetes.io/cluster/cluster"
    value = "owned"
    propagate_at_launch = "true"
  }

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
