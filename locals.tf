locals {
  # Standardize naming across the project
  prefix = "${var.project_name}-${var.environment}"
  
  # Collection of microservices for dynamic OCIR repository creation
  microservices = toset([
    "auth-app",
    "product-app",
    "cart-app",
    "purchase-app"
  ])

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # --- Network Module Input Definitions ---
  vcn_cidr = "10.0.0.0/16"

  # Map for Person 1's dynamic subnet creation
  subnets = {
    api = {
      cidr_block = "10.0.0.0/28"
      is_public  = true
    }
    lb = {
      cidr_block = "10.0.0.16/28"
      is_public  = true
    }
    workers = {
      cidr_block = "10.0.16.0/20"
      is_public  = false
    }
    pods = {
      cidr_block = "10.0.32.0/19"
      is_public  = false
    }
  }

  # Route table definitions matching Person 1's network entity lookups
  route_tables = {
    public = [
      {
        destination        = "0.0.0.0/0"
        destination_type   = "CIDR_BLOCK"
        network_entity_key = "igw"
      }
    ]
    private = [
      {
        destination        = "0.0.0.0/0"
        destination_type   = "CIDR_BLOCK"
        network_entity_key = "nat"
      }
    ]
  }
}