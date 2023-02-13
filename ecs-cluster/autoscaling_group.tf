data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

locals {
  userdata = templatefile("${path.module}/userdata.tpl", {
    cluster_name = aws_ecs_cluster.main.name
  })
}

resource "aws_launch_configuration" "main" {
  name_prefix = "${var.cluster_name}-ecs"

  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name

  instance_type               = var.instance_type
  image_id                    = data.aws_ami.ecs_ami.image_id
  associate_public_ip_address = false
  security_groups             = concat(var.security_group_ids, [aws_security_group.main.id])

  root_block_device {
    volume_type = "standard"
  }

  ebs_block_device {
    device_name = "/dev/xvdcz"
    volume_type = "standard"
    encrypted   = true
  }

  user_data = base64encode(local.userdata)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name = "${var.cluster_name}-ecs"

  launch_configuration = aws_launch_configuration.main.id
  termination_policies = ["OldestLaunchConfiguration", "Default"]
  vpc_zone_identifier  = var.subnet_ids

  desired_capacity = var.desired_capacity
  max_size         = var.max_size
  min_size         = var.min_size

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-ecs"
    propagate_at_launch = true
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }
}
