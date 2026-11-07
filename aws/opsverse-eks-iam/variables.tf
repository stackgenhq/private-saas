## Fill in with your network configs
variable "cluster_name" {}
variable "cluster_version" {}
variable "aws_region" {}
variable "s3_bucket_name" {}
variable "subnet_ids" { type = list }
variable "vpc_id" {}
variable "aws_profile" {}
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "vpc_network_azs" { type = list }
variable "private_subnet_cidr" { type = list }
variable "public_subnet_cidr" { type = list }
variable "node_type" { type = string }
variable "node_disk_size" {
  type    = number
  default = 50
}
# Defaults to "<cluster_name>-s3-pod-role"; older clusters used "eks-opsverse-s3-pod-role"
variable "loki_pod_role_name" {
  type    = string
  default = null
}
# Defaults to "<cluster_name>-pod-permissions"; older clusters used "opsverse-eks-pod-permissions"
variable "loki_pod_policy_name" {
  type    = string
  default = null
}