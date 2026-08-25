# One NSG per subnet purpose, for_each over the same keys as the subnets
# themselves so they stay in sync (api_endpoint, load_balancer, worker_nodes, pods).
resource "oci_core_network_security_group" "this" {
  for_each = var.subnets

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-${replace(each.key, "_", "-")}-nsg"
}

# Ingress rules - for_each over local.ingress_rules_flat 
resource "oci_core_network_security_group_security_rule" "ingress" {
  for_each = local.ingress_rules_flat

  network_security_group_id = oci_core_network_security_group.this[each.value.nsg_key].id
  direction                  = "INGRESS"
  protocol                   = each.value.protocol
  source                     = each.value.source
  source_type                = each.value.source == local.oci_services_cidr ? "SERVICE_CIDR_BLOCK" : "CIDR_BLOCK"
  description                = each.value.description

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" && try(each.value.port_min, null) != null ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }

  dynamic "icmp_options" {
    for_each = each.value.protocol == "1" && try(each.value.icmp_type, null) != null ? [1] : []
    content {
      type = each.value.icmp_type
      code = each.value.icmp_code
    }
  }
}

# Egress rules - for_each over local.egress_rules_flat
resource "oci_core_network_security_group_security_rule" "egress" {
  for_each = local.egress_rules_flat

  network_security_group_id = oci_core_network_security_group.this[each.value.nsg_key].id
  direction                  = "EGRESS"
  protocol                   = each.value.protocol
  destination                = each.value.destination
  destination_type           = each.value.destination == local.oci_services_cidr ? "SERVICE_CIDR_BLOCK" : "CIDR_BLOCK"
  description                = each.value.description

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" && try(each.value.port_min, null) != null ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }

  dynamic "icmp_options" {
    for_each = each.value.protocol == "1" && try(each.value.icmp_type, null) != null ? [1] : []
    content {
      type = each.value.icmp_type
      code = each.value.icmp_code
    }
  }
}
