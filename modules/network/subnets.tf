# The 4 subnets (API endpoint, load balancer, worker nodes, pods), built
# from the var.subnets map with for_each instead of 4 separate blocks.
# Each picks its route table based on is_public.
resource "oci_core_subnet" "this" {
  for_each = var.subnets

  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = each.value.cidr_block
  display_name               = "${var.project_name}-${replace(each.key, "_", "-")}-subnet"
  dns_label                  = replace(each.key, "_", "")
  route_table_id             = each.value.is_public ? oci_core_route_table.public_rt.id : oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_vcn.main.default_security_list_id]
  prohibit_public_ip_on_vnic = !each.value.is_public
}