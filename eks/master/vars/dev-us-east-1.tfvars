env               = "dev"
aws_account       = "149592216170"
aws_region        = "us-east-1"
vpc_name          = ""
cluster_name      = "stage"
cluster_version   = "1.29"
addons_version    = {
  aws_ebs_csi_driver = "v1.27.0-eksbuild.1",
  coredns            = "v1.11.1-eksbuild.6",
  vpc_cni            = "v1.16.2-eksbuild.1"
}
