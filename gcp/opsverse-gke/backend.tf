terraform {
  # Pass the state bucket/prefix at init, e.g.
  #   terraform init -backend-config="bucket=<state-bucket>" -backend-config="prefix=private-saas/<cluster_name>"
  backend "gcs" {}
}

