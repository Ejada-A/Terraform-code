variable "compartment_ocid" {
  description = "OCID of the compartment to build networking resources in"
  type        = string
}

variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "ecommerce"
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
      cidr_block = "10.0.0.0/28"   # small - only the OKE control plane endpoint lives here
      is_public  = true
    }
    load_balancer = {
      cidr_block = "10.0.1.0/24"
      is_public  = true
    }
    worker_nodes = {
      cidr_block = "10.0.10.0/24"
      is_public  = false
    }
    pods = {
      cidr_block = "10.0.20.0/20"  # larger - VCN-native pod networking needs room, one IP per pod
      is_public  = false
    }
  }
}

# NSG rules, also defined as a map. Each key is an NSG name (matches a
# subnet key above); each value is a list of rule objects.
variable "nsg_ingress_rules" {
  description = "Map of NSG name => list of ingress rules for that NSG"
  type = map(list(object({
    description = string
    protocol    = string # "6" = TCP, "17" = UDP, "all" = all
    source      = string
    port_min    = optional(number)
    port_max    = optional(number)
  })))
  default = {
    api_endpoint = [
      {
        description = "Allow worker nodes to reach the Kubernetes API"
        protocol    = "6"
        source      = "10.0.10.0/24"
        port_min    = 6443
        port_max    = 6443
      }
    ]
    load_balancer = [
      {
        description = "Allow public HTTP"
        protocol    = "6"
        source      = "0.0.0.0/0"
        port_min    = 80
        port_max    = 80
      },
      {
        description = "Allow public HTTPS"
        protocol    = "6"
        source      = "0.0.0.0/0"
        port_min    = 443
        port_max    = 443
      }
    ]
    worker_nodes = [
      {
        description = "Allow traffic from the load balancer subnet"
        protocol    = "6"
        source      = "10.0.1.0/24"
        port_min    = 30000
        port_max    = 32767
      },
      {
        description = "Allow pod-to-node traffic"
        protocol    = "all"
        source      = "10.0.20.0/20"
      }
    ]
    pods = [
      {
        description = "Allow pod-to-pod traffic (VCN-native networking)"
        protocol    = "all"
        source      = "10.0.20.0/20"
      }
    ]
  }
}

variable "enable_flow_logs" {
  description = "Toggle VCN flow logging on/off -demonstrates conditional (count) resource creation"
  type        = bool
  default     = false
}
