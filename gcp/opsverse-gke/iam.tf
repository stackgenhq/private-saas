resource "google_storage_bucket_iam_binding" "bucket_admin" {
  bucket     = var.bucket_name
  role       = "roles/storage.objectAdmin"
  members    = [join(":", ["serviceAccount", module.opsverse-workload-identity.gcp_service_account.email])]
  depends_on = [module.bucket, module.opsverse-workload-identity]
}

module "opsverse-workload-identity" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "32.0.4"
  use_existing_k8s_sa = true
  name                = "loki-sa-${var.service_account_base_name}"
  k8s_sa_name         = "${var.service_account_base_name}-observe-backend-loki"
  namespace           = "${var.service_account_base_name}-observe"
  project_id          = var.gcp_project_id
  roles               = ["roles/iam.serviceAccountTokenCreator", "roles/viewer"]
  annotate_k8s_sa     = false
}


