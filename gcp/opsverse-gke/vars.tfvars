gcp_project_id = "opsverse-dev-poc"
gcp_region     = "us-east4"
cluster_name   = "opsverse-gke-cluster"
# The bucket name should be of the format devopsnow-loki-<customer_name>-<stack_name>
#If customer name is kylaq , the stack name is decided as alpha then bucket_name = "devopsnow-loki-kylaq-alpha" 
bucket_name = "devopsnow-loki-<customer_name>-<stack_name>"


#If customer name is kylaq , the stack name is decided as alpha then service_account_base_name = "kylaq-alpha"
#Please Note: The stack name used here should be the same one when trying to launch the stack through the admin console.
service_account_base_name = "<customer_name>-<stack_name>"

# It is recommended to specify the exact version (With exact Major, Minor and Patch) you want to use.
# Since `auto_upgrade` option is disabled, specifying the general version is not recommended.
# List valid versions with: gcloud container get-server-config --region <region> --format="value(validMasterVersions)"
cluster_version = "1.36.5-gke.1982000"
# release_channel is set as UNSPECIFIED because the auto upgradation of nodes is disabled.
# This must be set to either `REGULAR` or `STABLE` in case if auto upgradation to be enabled.
release_channel     = "UNSPECIFIED"
auto_upgrade_nodes  = false
deletion_protection = false
network_name        = "opsverse-gke-network"
# ObserveNow is memory-bound (typically 8-20 GiB per core used), so default to memory-optimized
# nodes (4 vCPU / 32 GiB, AMD, gets sustained-use discounts). e2-standard-4 is fine for small/test stacks.
node_type           = "n2d-highmem-4"
node_locations      = "us-east4-a,us-east4-b,us-east4-c"

# 3 Public Subnets and 3 Private Subnets by default
# This can be changed as per requirements
subnets = [
  {
    subnet_name   = "opsverse-gke-cluster-apps-public-a"
    subnet_ip     = "10.245.0.0/19"
    subnet_region = "us-east4"
  },
  {
    subnet_name   = "opsverse-gke-cluster-apps-public-b"
    subnet_ip     = "10.245.32.0/19"
    subnet_region = "us-east4"
  },
  {
    subnet_name   = "opsverse-gke-cluster-apps-public-c"
    subnet_ip     = "10.245.64.0/19"
    subnet_region = "us-east4"
  },
  {
    subnet_name   = "opsverse-gke-cluster-apps-private-a"
    subnet_ip     = "10.245.96.0/19"
    subnet_region = "us-east4"
  },
  {
    subnet_name   = "opsverse-gke-cluster-apps-private-b"
    subnet_ip     = "10.245.128.0/19"
    subnet_region = "us-east4"
  },
  {
    subnet_name   = "opsverse-gke-cluster-apps-private-c"
    subnet_ip     = "10.245.160.0/19"
    subnet_region = "us-east4"
  },
]

secondary_ranges = {
  "opsverse-gke-cluster-apps-public-a" = [
    {
      range_name    = "ip-range-pods"
      ip_cidr_range = "172.18.128.0/19"
    },
    {
      range_name    = "ip-range-services"
      ip_cidr_range = "172.18.160.0/19"
    },
  ],
  "opsverse-gke-cluster-apps-public-b" = [
    {
      range_name    = "ip-range-pods"
      ip_cidr_range = "172.18.192.0/19"
    },
    {
      range_name    = "ip-range-services"
      ip_cidr_range = "172.18.224.0/19"
    },
  ],
  "opsverse-gke-cluster-apps-public-c" = [
    {
      range_name    = "ip-range-pods"
      ip_cidr_range = "172.19.0.0/19"
    },
    {
      range_name    = "ip-range-services"
      ip_cidr_range = "172.19.32.0/19"
    },
  ],
  "opsverse-gke-cluster-apps-private-a" = [
    {
      range_name    = "ip-range-pods"
      ip_cidr_range = "172.19.64.0/19"
    },
    {
      range_name    = "ip-range-services"
      ip_cidr_range = "172.19.96.0/19"
    },
  ],
  "opsverse-gke-cluster-apps-private-b" = [
    {
      range_name    = "ip-range-pods"
      ip_cidr_range = "172.19.128.0/19"
    },
    {
      range_name    = "ip-range-services"
      ip_cidr_range = "172.19.160.0/19"
    },
  ],
  "opsverse-gke-cluster-apps-private-c" = [
    {
      range_name    = "ip-range-pods"
      ip_cidr_range = "172.19.192.0/19"
    },
    {
      range_name    = "ip-range-services"
      ip_cidr_range = "172.19.224.0/19"
    },
  ]
}
