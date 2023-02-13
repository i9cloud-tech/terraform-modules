resource "aws_security_group" "main" {
  name        = "${var.cluster_name}-asg"
  description = "${var.cluster_name} ASG security group"
  vpc_id      = var.vpc_id

  tags = {
    Terraform = "true"
  }
}

resource "aws_security_group_rule" "main" {
  description       = "All outbound"
  security_group_id = aws_security_group.main.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}