##############
# Loki storage buckets
##############

module "s3_bucket_opsverse" {
  source = "../modules/s3"

  bucket_name = var.s3_bucket_name
  bucket_tags = {
    "Name"         = var.s3_bucket_name
    "Environment" = "opsverse-cluster"
    "GeneratedBy" = "OpsVerse"
  }
}

# DRIFT-REMEDIATION (wf-iac-drift-remediation-019f548c430b7cdd):
# A bucket policy was applied to opsverse-eks-bucket outside of Terraform.
# This resource codifies it. Run: terraform import aws_s3_bucket_policy.opsverse_loki opsverse-eks-bucket
# before applying, to import the existing policy into state.
resource "aws_s3_bucket_policy" "opsverse_loki" {
  bucket = var.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLokiPodAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.iam_for_loki_pods.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}
