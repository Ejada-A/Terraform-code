output "vcn_id" {
  value = oci_core_vcn.main.id
}

output "subnet_ids" {
  description = "Map of subnet name => OCID, e.g. subnet_ids[\"worker_nodes\"]"
  value       = { for k, v in oci_core_subnet.this : k => v.id }
}

output "nsg_ids" {
  description = "Map of NSG name => OCID, e.g. nsg_ids[\"worker_nodes\"]"
  value       = { for k, v in oci_core_network_security_group.this : k => v.id }
}

output "api_endpoint_subnet_id" {
  value = oci_core_subnet.this["api_endpoint"].id
}

output "load_balancer_subnet_id" {
  value = oci_core_subnet.this["load_balancer"].id
}

output "worker_nodes_subnet_id" {
  value = oci_core_subnet.this["worker_nodes"].id
}

output "pods_subnet_id" {
  value = oci_core_subnet.this["pods"].id
}