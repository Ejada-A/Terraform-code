variable "compartment_ocid" {
  description = "OCID of the compartment to build networking resources in"
  type        = string
}

variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "Cloud-grad-project"
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

# Subnets, defined as a map. Each key becomes part of
# the subnet's name; "public" controls which route table/NSG rules it gets.
variable "subnets" {
  description = "Map of subnet name => config. Covers API endpoint, load balancer, worker nodes, and pods subnets."
  type = map(object({
    cidr_block = string
    is_public  = bool
  }))
  default = {
    api_endpoint = {
      cidr_block = "10.0.0.0/28"   # 10.0.0.0 - 10.0.0.15 - Kubernetes API access (kubectl)
      is_public  = true
    }
    load_balancer = {
      cidr_block = "10.0.0.16/28" # 10.0.0.16 - 10.0.0.31 - public entry point for the app
      is_public  = true
    }
    worker_nodes = {
      cidr_block = "10.0.16.0/20" # 10.0.16.0 - 10.0.31.255 - hosts the VMs running all pods
      is_public  = false
    }
    pods = {
      cidr_block = "10.0.32.0/19"  # 10.0.32.0 - 10.0.63.255 - larger than worker nodes:
      is_public  = false            # each node hosts many pods, each needing its own IP
    }
  }
}

variable "enable_nodeport_public_access" {
  description = "Allow 0.0.0.0/0 to reach worker nodes on the NodePort range (30000-32767) directly, bypassing the load balancer. Doc marks this optional."
  type        = bool
  default     = false
}

variable "enable_worker_ssh_access" {
  description = "Allow inbound SSH (port 22) to worker nodes, for troubleshooting. Doc marks this optional."
  type        = bool
  default     = false
}

variable "enable_pods_outbound_internet" {
  description = "Allow pods outbound internet access on 443, beyond OCI services. Doc marks this optional."
  type        = bool
  default     = false
}

variable "enable_worker_general_outbound" {
  description = "Allow worker nodes general outbound internet access on all TCP ports, beyond what's needed for OKE/API/NAT. Doc marks this optional."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Toggle VCN flow logging on/off - demonstrates conditional (count) resource creation"
  type        = bool
  default     = false
}