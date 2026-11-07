terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.63.0"
    }
  }

  required_version = ">= 1.3"

  # State lives in S3. Pass the bucket/key/region at init, e.g.
  #   terraform init -backend-config="bucket=<state-bucket>" \
  #     -backend-config="key=private-saas/<cluster_name>/terraform.tfstate" -backend-config="region=<region>"
  backend "s3" {}
}
