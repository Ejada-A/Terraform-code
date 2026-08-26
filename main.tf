
module "network" {
  source = "./modules/network"

  compartment_ocid = var.compartment_ocid
  project_name     = local.prefix

  enable_worker_ssh_access       = true
  enable_worker_general_outbound = true
  enable_pods_outbound_internet  = true
  enable_nodeport_public_access  = true
  enable_flow_logs               = false
}


module "oke" {
  source = "./modules/oke"

  compartment_id = var.compartment_ocid
  vcn_id         = module.network.vcn_id

  api_endpoint_subnet_id = module.network.subnet_ids["api_endpoint"]
  worker_nodes_subnet_id = module.network.subnet_ids["worker_nodes"]
  pods_subnet_id         = module.network.subnet_ids["pods"]

  # --- Security & Access ---
  api_endpoint_nsg_ids = [module.network.nsg_ids["api_endpoint"]]
  worker_nodes_nsg_ids = [module.network.nsg_ids["worker_nodes"]]
  pods_nsg_ids         = [module.network.nsg_ids["pods"]]

  ssh_public_key = var.ssh_public_key

  # --- OKE Cluster Configurations ---
  cluster_display_name = "${local.prefix}-cluster"
  kubernetes_version   = "v1.34.2"
  is_public_ip_enabled = true

  # --- Node Pool Configurations ---
  node_pool_display_name = "${local.prefix}-node-pool"
  node_shape             = var.node_shape
  node_ocpus             = var.node_ocpus
  node_memory_in_gbs     = var.node_memory_in_gbs
  node_image_id          = data.oci_core_images.oke_node_image.images[0].id
  node_pool_size         = var.node_count >= 2 ? var.node_count : 2
}


#---------------------------------------------------------------


# as we don't have an access to dynamic group, we will make auth token and work with kubectl
# 
# resource "oci_identity_dynamic_group" "oke_nodes" {
#   compartment_id = var.tenancy_ocid
#   name           = "${local.prefix}-oke-nodes-dg"
#   description    = "Dynamic Group for OKE Worker Nodes"
#   matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
# }

# resource "oci_identity_policy" "oke_nodes_policy" {
#   compartment_id = var.compartment_ocid
#   name           = "${local.prefix}-oke-nodes-policy"
#   description    = "Allow OKE nodes to pull images and read secrets"

#   statements = [
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to read repos in compartment id ${var.compartment_ocid}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to read secret-family in compartment id ${var.compartment_ocid}"
#   ]
# }