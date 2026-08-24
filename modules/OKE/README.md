## OKE Cluster Module Documentation

### Module Purpose

This Terraform module provisions a managed Oracle Kubernetes Engine (OKE) cluster and its associated worker node pool on Oracle Cloud Infrastructure (OCI). It is specifically architected to enforce **VCN-native pod networking**, ensuring pods receive routable IP addresses directly from a dedicated subnet rather than relying on a Flannel overlay. The module dynamically distributes compute resources across available domains and incorporates a hardcoded fail-safe to guarantee a minimum of two worker nodes for redundancy.

---

### Inputs

| Variable | Type | Description |
| --- | --- | --- |
| **`compartment_id`** | `string` | The OCID of the target OCI compartment. |
| **`vcn_id`** | `string` | The OCID of the Virtual Cloud Network (VCN). |
| **`api_endpoint_subnet_id`** | `string` | OCID of the public subnet for the Kubernetes API endpoint. |
| **`worker_nodes_subnet_id`** | `string` | OCID of the private subnet hosting the worker node VMs. |
| **`pods_subnet_id`** | `string` | OCID of the private subnet supplying native IPs to pods. |
| **`cluster_display_name`** | `string` | Display name for the OKE cluster. |
| **`kubernetes_version`** | `string` | Kubernetes version for the control plane and worker nodes. |
| **`is_public_ip_enabled`** | `bool` | Determines if the Kubernetes API endpoint receives a public IP. |
| **`node_pool_display_name`** | `string` | Display name for the worker node pool. |
| **`node_shape`** | `string` | Compute shape assigned to the worker nodes (e.g., `VM.Standard.E4.Flex`). |
| **`node_ocpus`** | `number` | Number of OCPUs assigned to each worker node. |
| **`node_memory_in_gbs`** | `number` | Amount of RAM (in GB) assigned to each worker node. |
| **`node_image_id`** | `string` | The OCID of the Oracle Linux OS image for the host machines. |
| **`node_pool_size`** | `number` | Target number of worker nodes (enforces a minimum of 2). |

---

### Outputs

| Output | Description |
| --- | --- |
| **`cluster_id`** | The OCID of the OKE cluster. Used by the root module to generate connection strings. |
| **`cluster_endpoints`** | Kubernetes API endpoint details, including both public and private IP addresses. |
| **`node_pool_id`** | The OCID of the managed worker node pool. |

