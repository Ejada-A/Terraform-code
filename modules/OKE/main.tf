locals {
  cluster_name = var.cluster_display_name
  pool_name    = var.node_pool_display_name
  worker_shape = var.node_shape
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.compartment_id
  vcn_id             = var.vcn_id
  kubernetes_version = var.kubernetes_version
  name               = local.cluster_name

  endpoint_config {
    is_public_ip_enabled = var.is_public_ip_enabled
    subnet_id            = var.api_endpoint_subnet_id
    nsg_ids              = var.api_endpoint_nsg_ids 
  }

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "oci_containerengine_node_pool" "oke_node_pool" {
  cluster_id         = oci_containerengine_cluster.oke_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = local.pool_name
  node_shape         = local.worker_shape
  ssh_public_key     = var.ssh_public_key

  node_shape_config {
    memory_in_gbs = var.node_memory_in_gbs
    ocpus         = var.node_ocpus
  }

  node_source_details {
    image_id    = var.node_image_id
    source_type = "IMAGE"
  }

  node_config_details {
    size = var.node_pool_size
    nsg_ids = var.worker_nodes_nsg_ids

    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.ads.availability_domains
      content {
        availability_domain = placement_configs.value.name
        subnet_id           = var.worker_nodes_subnet_id
      }
    }
    node_pool_pod_network_option_details {
      cni_type       = "OCI_VCN_IP_NATIVE"
      pod_subnet_ids = [var.pods_subnet_id]
      pod_nsg_ids    = var.pods_nsg_ids
    }
  }


  node_eviction_node_pool_settings {
    eviction_grace_duration = "PT60M"
  }
  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}