terraform {
  backend "s3" {
    bucket                      = "ecommerce-terraform-state"
    key                         = "oke-cluster/terraform.tfstate"
    region                      = "me-jeddah-1"
    endpoints                   = { s3 = "https://axkjllkftxfz.compat.objectstorage.me-jeddah-1.oraclecloud.com" }
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.30.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}


provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}
