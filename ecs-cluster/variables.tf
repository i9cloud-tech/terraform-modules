variable "cluster_name" {
  type = string
}

variable "instance_type" {
  description = "The instance type to use."
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  description = "The id of the VPC to launch resources in."
}

variable "subnet_ids" {
  description = "A list of subnet IDs to launch resources in."
  type        = list(string)
}

variable "desired_capacity" {
  description = "Desired instance count."
  type        = string
  default     = 0
}

variable "max_size" {
  description = "Maxmimum instance count."
  type        = string
  default     = 5
}

variable "min_size" {
  description = "Minimum instance count."
  type        = string
  default     = 0
}

variable "security_group_ids" {
  description = "A list of security group ids to attach to the autoscaling group"
  type        = list(string)
  default     = []
}
