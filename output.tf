output "cluster_id" {
  description = "The OCID of the OKE Cluster"
  value       = module.oke.cluster_id
}

output "cluster_endpoint" {
  description = "The public endpoint for the Kubernetes API"
  value       = module.oke.cluster_endpoints[0].public_endpoint
}

output "kubeconfig_command" {
  description = "Run this OCI CLI command to generate your local kubeconfig"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${module.oke.cluster_id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0  --kube-endpoint PUBLIC_ENDPOINT"
}

output "load_balancer_subnet_id" {
  description = "The OCID of the public subnet for Load Balancers"
  value       = module.network.load_balancer_subnet_id
}
output "load_balancer_nsg_id" {
  description = "The OCID of the NSG for Load Balancers"
  value       = module.network.nsg_ids["load_balancer"]
}
