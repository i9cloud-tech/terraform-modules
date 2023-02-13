resource "aws_ecs_cluster" "main" {
  name = "${var.cluster_name}-${var.environment}-cluster"
  tags = {
    Name = "${var.cluster_name}-ecs"
  }
}
