# Internet Gateway - lets the PUBLIC subnets (API endpoint, load balancer)
# reach/be reached from the internet.
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-igw"
  enabled        = true
}

# NAT Gateway - lets the PRIVATE subnets (worker nodes, pods) reach the
# internet outbound only (e.g. to pull container images), without being
# reachable from the internet inbound.
resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-nat"
}

# Service Gateway - lets private subnets reach OCI services (OCIR, Object
# Storage) directly over Oracle's network instead of the public internet.
resource "oci_core_service_gateway" "svc_gw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-svc-gw"

  services {
    service_id = data.oci_core_services.all_services.services[0]["id"]
  }
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}