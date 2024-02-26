variable "aws_account" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "env" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "addons_version" {
  type = object({
    aws_ebs_csi_driver = string,
    coredns            = string,
    vpc_cni            = string
  })
}
