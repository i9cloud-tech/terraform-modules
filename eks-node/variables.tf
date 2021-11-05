variable "cluster_name" {
  type = string
}

variable "node_name" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "instance_types" {
  type = list(string)
}
