# --- Identity & Network Context ---
variable "compartment_id" {
  description = "The OCID of the target compartment."
  type        = string
}

variable "vcn_id" {
  description = "The OCID of the Virtual Cloud Network."
  type        = string
}

variable "api_endpoint_subnet_id" {
  description = "OCID of the public subnet for the K8s API endpoint."
  type        = string
}

variable "worker_nodes_subnet_id" {
  description = "OCID of the private subnet hosting worker node VMs."
  type        = string
}

variable "pods_subnet_id" {
  description = "OCID of the private subnet supplying native IP addresses to pods."
  type        = string
}

# --- Security & Access ---
variable "api_endpoint_nsg_ids" {
  description = "List of NSG OCIDs for the Kubernetes API endpoint."
  type        = list(string)
}

variable "worker_nodes_nsg_ids" {
  description = "List of NSG OCIDs for the worker nodes."
  type        = list(string)
}

variable "pods_nsg_ids" {
  description = "List of NSG OCIDs for the VCN-native pods."
  type        = list(string)
}

variable "ssh_public_key" {
  description = "The SSH public key string for accessing worker nodes."
  type        = string
}

# --- OKE Cluster Configurations ---
variable "cluster_display_name" {
  description = "Display name for the OKE cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the control plane and worker nodes."
  type        = string
}

variable "is_public_ip_enabled" {
  description = "Determines whether the API endpoint receives a public IP."
  type        = bool
}

# --- Node Pool Configurations ---
variable "node_pool_display_name" {
  description = "Display name for the worker node pool."
  type        = string
}

variable "node_shape" {
  description = "Compute shape assigned to worker nodes."
  type        = string
}

variable "node_ocpus" {
  description = "Number of OCPUs assigned to each worker node."
  type        = number
}

variable "node_memory_in_gbs" {
  description = "Amount of RAM (in GB) assigned to each worker node."
  type        = number
}

variable "node_image_id" {
  description = "The OCID of the Oracle Linux OS image for worker nodes."
  type        = string
}

variable "node_pool_size" {
  description = "Target number of worker nodes (enforces minimum of 2 for redundancy)."
  type        = number
  default     = 2
}