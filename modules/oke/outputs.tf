output "cluster_id" {
  description = "The OCID of the OKE cluster. Person 3 uses this to output the kubeconfig command."
  value       = oci_containerengine_cluster.oke_cluster.id
}

output "cluster_endpoints" {
  description = "Kubernetes API endpoint details."
  value       = oci_containerengine_cluster.oke_cluster.endpoints
}

output "node_pool_id" {
  description = "The OCID of the managed worker node pool."
  value       = oci_containerengine_node_pool.oke_node_pool.id
}