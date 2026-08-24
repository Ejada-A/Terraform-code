## OKE Cluster Module

### Description
This Terraform module provisions a managed Oracle Kubernetes Engine (OKE) cluster and its associated worker node pool on Oracle Cloud Infrastructure (OCI). 

It is architected strictly for **VCN-native pod networking** and integrates deeply with **Network Security Groups (NSGs)** to decouple security rules from subnet topology. The module dynamically distributes compute resources across available domains, injects an SSH key for node troubleshooting, and requires explicit variable passing from a root orchestrator to ensure architectural compliance.

---

### Inputs

| Variable | Type | Description |
| :--- | :--- | :--- |
| **`compartment_id`** | `string` | The OCID of the target OCI compartment. |
| **`vcn_id`** | `string` | The OCID of the Virtual Cloud Network (VCN). |
| **`api_endpoint_subnet_id`** | `string` | OCID of the public subnet for the Kubernetes API endpoint. |
| **`worker_nodes_subnet_id`** | `string` | OCID of the private subnet hosting the worker node VMs. |
| **`pods_subnet_id`** | `string` | OCID of the private subnet supplying native IPs to pods. |
| **`api_endpoint_nsg_ids`** | `list(string)` | List of NSG OCIDs applied to the API endpoint. |
| **`worker_nodes_nsg_ids`** | `list(string)` | List of NSG OCIDs applied to the worker nodes. |
| **`pods_nsg_ids`** | `list(string)` | List of NSG OCIDs applied to the VCN-native pods. |
| **`ssh_public_key`** | `string` | SSH public key string for node-level troubleshooting access. |
| **`cluster_display_name`** | `string` | Display name for the OKE cluster. |
| **`kubernetes_version`** | `string` | Kubernetes version for the control plane and worker nodes. |
| **`is_public_ip_enabled`** | `bool` | Determines if the Kubernetes API endpoint receives a public IP. |
| **`node_pool_display_name`** | `string` | Display name for the worker node pool. |
| **`node_shape`** | `string` | Compute shape assigned to the worker nodes (e.g., `VM.Standard.E4.Flex`). |
| **`node_ocpus`** | `number` | Number of OCPUs assigned to each worker node. |
| **`node_memory_in_gbs`** | `number` | Amount of RAM (in GB) assigned to each worker node. |
| **`node_image_id`** | `string` | The OCID of the Oracle Linux OS image for the host machines. |
| **`node_pool_size`** | `number` | Target number of worker nodes (defaults to 2 for redundancy). |

---

### Outputs

| Output | Description |
| :--- | :--- |
| **`cluster_id`** | The OCID of the OKE cluster. |
| **`cluster_endpoints`** | Kubernetes API endpoint details (public and private IP addresses). |
| **`node_pool_id`** | The OCID of the managed worker node pool. |