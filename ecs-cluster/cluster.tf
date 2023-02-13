resource "aws_ecs_cluster" "aws_ecs_cluster" {
  name = "${var.cluster_name}-${var.environment}-cluster"
  tags = {
    Name = "${var.cluster_name}-ecs"
  }
}