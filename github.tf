# This automatically adds the new CLUSTER_OCID to your GitHub Repository Secrets
resource "github_actions_secret" "cluster_ocid" {
  repository      = var.github_repo
  secret_name     = "CLUSTER_OCID"
  value           = module.oke.cluster_id
}
