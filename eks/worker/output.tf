output "instance_role" {
  value = aws_iam_role.node_role.arn
}

output "node_sgs" {
  value = [
    aws_security_group.node_ssh.id,
    var.cluster.sg_id
  ]
} 
