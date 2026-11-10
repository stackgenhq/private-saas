resource "local_file" "kubeconfig-opsverse-gke-cluster" {
  content  = module.opsverse-gke-cluster-auth.kubeconfig_raw
  filename = "kubeconfig_${var.cluster_name}"
}

module "opsverse-gke-cluster" {
  source                   = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                  = "32.0.4"
  kubernetes_version       = var.cluster_version
  # Client certificates are a legacy auth method; use gcloud / workload identity instead
  issue_client_certificate = false
  project_id               = var.gcp_project_id
  name                     = var.cluster_name
  regional                 = true
  region                   = var.gcp_region
  network                  = module.opsverse-gke-cluster-network.network_name
  subnetwork               = module.opsverse-gke-cluster-network.subnets_names[0]
  ip_range_pods            = "ip-range-pods"
  ip_range_services        = "ip-range-services"
  deletion_protection      = var.deletion_protection
  release_channel          = var.release_channel
  node_pools = [
    {
      name           = "opsverse-node-pool"
      machine_type   = var.node_type
      node_locations = var.node_locations

      // nodes per location (this multiplied by number
      // of locations will be the current node count)
      node_count         = 1
      initial_node_count = 3
      min_count          = 3
      max_count          = 3
      disk_size_gb       = var.node_disk_size
      disk_type          = "pd-balanced"
      autoscaling        = false
      auto_upgrade       = var.auto_upgrade_nodes
    },
  ]
}

module "opsverse-gke-cluster-auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version      = "32.0.4"
  depends_on   = [module.opsverse-gke-cluster]
  project_id   = var.gcp_project_id
  location     = module.opsverse-gke-cluster.location
  cluster_name = module.opsverse-gke-cluster.name
}