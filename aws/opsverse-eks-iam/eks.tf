# Creates a 3-node EKS cluster. You may additionally want to:
#   - add more subnets to span whichever networks you want
#   - add manage_aws_auth="true" in case you do auth maps here too 
#   - change cluster/module name to one that fits your org conventions

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.opsverse-eks-cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.opsverse-eks-cluster.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.default.token
}

data "aws_eks_cluster_auth" "default" {
  name = module.opsverse-eks-cluster.cluster_name
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

module "opsverse-eks-cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.23.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  # Cluster endpoint access is set to public and private.
  # In this config, the cluster endpoint is accessible from outside of the VPC. Worker node traffic to the endpoint will stay within the VPC.
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access = true

  // Need at least 2 AZs for EKS to create cluster
  # Uncomment this if a customer already has a VPC and Subnets
  # subnet_ids      = [
  #                   "${var.subnet_ids[0]}",
  #                   "${var.subnet_ids[1]}",
  #                   ]
  # vpc_id          = "${var.vpc_id}"
  
  # Uncomment this if a new VPC has to be created as part of the cluster creation
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = flatten([module.vpc.private_subnets, module.vpc.public_subnets])

  enable_irsa     = "true"
  # EKS Addons
  cluster_addons = {
    # Enable EBS CSI Driver by default
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }
  enable_cluster_creator_admin_permissions = true
  eks_managed_node_group_defaults = {
    disk_size      = 50
  }

  eks_managed_node_groups = {
    user_group_one = {
      name = "node-group-1"
      instance_types = ["${var.node_type}"]
      ami_type       = "AL2_x86_64"
      capacity_type  = "ON_DEMAND"
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      # use_custom_launch_template = false
      min_size     = 2
      max_size     = 4
      # desired_size managed by Cluster Autoscaler -- see lifecycle.ignore_changes below
      desired_size = 3
      root_volume_type = "gp2"

      # Uncomment this if a customer already has a VPC and Subnets
      # subnets = [
      #   "${var.subnet_ids[0]}",
      #   "${var.subnet_ids[1]}"
      # ]

      # Uncomment this if a new VPC has to be created as part of the cluster creation
      subnet_ids      = module.vpc.private_subnets

      lifecycle {
        ignore_changes = [desired_size]
      }
    }
  }
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.opsverse-eks-cluster.cluster_name}"
  provider_url                  = module.opsverse-eks-cluster.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

module "aws-auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  manage_aws_auth_configmap = true

  # Please add all the users who wants to access the cluster
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/<user>"
      username = "<user>"
      groups   = ["system:masters"]
    },
  ]
  depends_on = [module.opsverse-eks-cluster, module.irsa-ebs-csi]
}
