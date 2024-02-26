terraform {
  backend "s3" {
    bucket = "tf-states"
    key    = "eks-master"
    region = "us-east-1"
  }
}
