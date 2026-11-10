# Creates a role for the Loki pods to access the pre-created S3 bucket
# for Loki backend.
#
# Assumption, the bucket var.s3_bucket is already created in same region 
#
# Note: if you changed module name in eks.tf from "opsverse-eks-cluster", please
#       update this script to replace "opsverse-eks-cluster".

# Names default to per-cluster so several clusters can share an account. Clusters created
# before this change used the fixed names below; set loki_pod_role_name /
# loki_pod_policy_name to keep them (renaming replaces the role and changes its ARN).
locals {
  loki_pod_role_name   = coalesce(var.loki_pod_role_name, "${var.cluster_name}-s3-pod-role")
  loki_pod_policy_name = coalesce(var.loki_pod_policy_name, "${var.cluster_name}-pod-permissions")
}

resource "aws_iam_role" "iam_for_loki_pods" {
  name = local.loki_pod_role_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${module.opsverse-eks-cluster.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition":  {
        "StringLike": {
          "${replace(module.opsverse-eks-cluster.oidc_provider_arn, "${element(split("/", module.opsverse-eks-cluster.oidc_provider_arn), 0)}/", "")}:sub": "system:serviceaccount:*:*"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "loki_pod_permissions" {
  name   = local.loki_pod_policy_name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.s3_bucket_name}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.s3_bucket_name}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "tag:GetResources",
                "cloudwatch:GetMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF 
}

resource "aws_iam_role_policy_attachment" "loki_pod_permissions" {
  role       = aws_iam_role.iam_for_loki_pods.name
  policy_arn = aws_iam_policy.loki_pod_permissions.arn
}

output "loki_pod_role_arn" {
  value = aws_iam_role.iam_for_loki_pods.arn 
}
