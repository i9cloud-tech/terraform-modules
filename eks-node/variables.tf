variable "cluster" {
  type = map
}

variable "cluster_name" {
  type = string
}

variable "node_name" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "instance_types" {
  type = list(string)
}

variable "autoscale_configs" {
  type    = map

  default = {
    desired_capacity              = 0
    min_size                      = 0
    max_size                      = 30
    on_demand_base_capacity       = 0
    on_demand_percentage_capacity = 30
  }
}
