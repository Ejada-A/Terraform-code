# Conditional VCN flow logs - only created if enable_flow_logs = true.
# Demonstrates count-based conditional resource creation.
resource "oci_logging_log_group" "flow_log_group" {
  count = var.enable_flow_logs ? 1 : 0

  compartment_id = var.compartment_ocid
  display_name   = "${var.project_name}-flow-log-group"
}

resource "oci_logging_log" "vcn_flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  display_name = "${var.project_name}-vcn-flow-log"
  log_group_id = oci_logging_log_group.flow_log_group[0].id
  log_type     = "SERVICE"

  configuration {
    source {
      category    = "all"
      resource    = oci_core_vcn.main.id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_ocid
  }

  is_enabled         = true
  retention_duration = 30
}