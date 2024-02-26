variable "cluster" {
  type = map
}

variable "node_name" {
  type = string
}

variable "node_label_key" {
  type    = string
  default = "Environment"
}

variable "node_label_value" {
  type    = string
  default = ""
}

variable "instance_version" {
  type    = string
  default = "1.22"
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "instance_types" {
  type = list(string)
}

variable "ssh_key_name" {
  type = string
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
