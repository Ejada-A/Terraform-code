variable "tenancy_ocid" {
  description = "The OCID of the OCI Tenancy"
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the OCI user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the OCI API key"
  type        = string
}

variable "private_key_path" {
  description = "The path to the OCI API private key file"
  type        = string
}


variable "region" {
  description = "The OCI region (e.g., us-ashburn-1)"
  type        = string
}

variable "availability_domains" {
  description = "List of availability domains in the region"
  type        = list(string)
}

variable "project_name" {
  description = "The project name used as a prefix for resources"
  type        = string
  default     = "groupa"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "ssh_public_key" {
  description = "SSH public key for worker node access (for troubleshooting)"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into worker nodes"
  type        = string
  default     = "0.0.0.0/0" # Change this in tfvars to a trusted IP/VPN!
}

variable "node_shape" {
  description = "Compute shape for OKE worker nodes"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "node_ocpus" {
  description = "Number of OCPUs for worker nodes (if using Flex shapes)"
  type        = number
  default     = 2
}

variable "node_memory_in_gbs" {
  description = "Memory in GBs for worker nodes (if using Flex shapes)"
  type        = number
  default     = 16
}

variable "node_count" {
  description = "Number of worker nodes per availability domain"
  type        = number
  default     = 2
}



# Looks up the latest Oracle Linux 8 image for the specified node shape
data "oci_core_images" "oke_node_image" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.node_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# --- GitHub Automation Variables ---
variable "github_token" {
  description = "GitHub Personal Access Token with repo access"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "The GitHub Organization or Username (e.g., Ejada-A)"
  type        = string
}

variable "github_repo" {
  description = "The name of the Terraform-code repository"
  type        = string
}
