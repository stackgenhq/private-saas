# Creates a 3-node EKS cluster. You may additionally want to:
#   - add more subnets to span whichever networks you want
#   - add manage_aws_auth="true" in case you do auth maps here too 
#   - change cluster/module name to one that fits your org conventions

provider "aws" {
  region = var.aws_region
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
      # EKS 1.30+ no longer marks gp2 as default; without a default StorageClass PVCs stay Pending
      configuration_values     = jsonencode({ defaultStorageClass = { enabled = true } })
    }
  }
  # The identity running terraform gets cluster-admin via an EKS access entry.
  # To grant other users/roles access, add them to `access_entries` (EKS access API), e.g.
  #   access_entries = {
  #     admin = {
  #       principal_arn = "arn:aws:iam::<account_id>:role/<role>"
  #       policy_associations = {
  #         admin = {
  #           policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #           access_scope = { type = "cluster" }
  #         }
  #       }
  #     }
  #   }
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    user_group_one = {
      name = "node-group-1"
      instance_types = [var.node_type]
      # AL2 AMIs aren't published for EKS 1.33+
      ami_type       = "AL2023_x86_64_STANDARD"
      capacity_type  = "ON_DEMAND"
      min_size     = 2
      max_size     = 4
      desired_size = 3
      # The module's launch template ignores disk_size, so set the root volume here
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_disk_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # Uncomment this if a customer already has a VPC and Subnets
      # subnets = [
      #   "${var.subnet_ids[0]}",
      #   "${var.subnet_ids[1]}"
      # ]

      # Uncomment this if a new VPC has to be created as part of the cluster creation
      subnet_ids      = module.vpc.private_subnets
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
