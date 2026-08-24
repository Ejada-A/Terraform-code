# One NSG per subnet purpose, for_each over the same keys as the subnets
# themselves so they stay in sync (api_endpoint, load_balancer, worker_nodes, pods).

resource "oci_core_network_security_group" "this" {
  for_each = var.subnets

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-${replace(each.key, "_", "-")}-nsg"
}

# Ingress rules - flattened so we can for_each over "nsg key + rule index"
# pairs, since each NSG can have multiple rules from the map in variables.tf.
locals {
  ingress_rules_flat = merge([
    for nsg_key, rules in var.nsg_ingress_rules : {
      for idx, rule in rules :
      "${nsg_key}-${idx}" => merge(rule, { nsg_key = nsg_key })
    }
  ]...)
}

resource "oci_core_network_security_group_security_rule" "ingress" {
  for_each = local.ingress_rules_flat

  network_security_group_id = oci_core_network_security_group.this[each.value.nsg_key].id
  direction                  = "INGRESS"
  protocol                   = each.value.protocol
  source                     = each.value.source
  source_type                = "CIDR_BLOCK"
  description                = each.value.description

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" && each.value.port_min != null ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }
}

# Egress: every NSG gets an "allow all outbound" rule - simplest safe
# default for a lab; tighten per-service if your report wants to show
# more granular egress control.
resource "oci_core_network_security_group_security_rule" "egress" {
  for_each = var.subnets

  network_security_group_id = oci_core_network_security_group.this[each.key].id
  direction                  = "EGRESS"
  protocol                   = "all"
  destination                = "0.0.0.0/0"
  destination_type           = "CIDR_BLOCK"
  description                = "Allow all outbound"
}