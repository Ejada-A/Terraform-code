# OCI Networking Module for OKE

Provisions the foundational, VCN-native networking infrastructure required for an Oracle
Kubernetes Engine (OKE) cluster on Oracle Cloud Infrastructure (OCI): a Virtual Cloud
Network (VCN), 4 purpose-built subnets, Internet/NAT/Service gateways, route tables, and
Network Security Groups (NSGs).

---

## 1. Subnets

Four subnets are provisioned, each dedicated to a single resource type. Pods physically run
on worker node hardware but draw their IPs from the separate **Pods** subnet via a second
VNIC attached to each node (VCN-native pod networking).

| Subnet | Type | Purpose | CIDR Range |
| --- | --- | --- | --- |
| **API Endpoint** | Public, regional | Kubernetes API access (`kubectl`) | `10.0.0.0/28` (10.0.0.0 – 10.0.0.15) |
| **Load Balancer** | Public, regional | Public entry point for the app | `10.0.0.16/28` (10.0.0.16 – 10.0.0.31) |
| **Worker Nodes** | Private, regional | Hosts the VMs running all pods | `10.0.16.0/20` (10.0.16.0 – 10.0.31.255) |
| **Pods** | Private, regional | IPs for individual pods (VCN-native) | `10.0.32.0/19` (10.0.32.0 – 10.0.63.255) |

The **Pods** subnet is sized larger than **Worker Nodes** (`/19` vs `/20`) per Oracle's
requirement, since each node can host many pods, each needing its own routable IP address.

## 2. Gateways

| Gateway | Attached to | Purpose |
| --- | --- | --- |
| **Internet Gateway** | API Endpoint, Load Balancer subnets | Inbound/outbound internet access for public subnets |
| **NAT Gateway** | Worker Nodes, Pods subnets | Outbound-only internet access for private subnets |
| **Service Gateway** | Worker Nodes, Pods subnets | Private, fast path to OCI services (e.g. OCIR) without traversing NAT |

## 3. Route Tables

Each subnet has its own route table.

| Subnet | Destination | Target |
| --- | --- | --- |
| API Endpoint (public) | `0.0.0.0/0` | Internet Gateway |
| Load Balancer (public) | `0.0.0.0/0` | Internet Gateway |
| Worker Nodes (private) | All `<region>` Services in Oracle Services Network | Service Gateway |
| Worker Nodes (private) | `0.0.0.0/0` | NAT Gateway |
| Pods (private) | All `<region>` Services in Oracle Services Network | Service Gateway |
| Pods (private) | `0.0.0.0/0` | NAT Gateway |

## 4. Security: Network Security Groups (NSGs)

Traffic is enforced via **NSGs rather than Security Lists**. In this specific design the two
would enforce identical traffic, since each subnet holds exactly one resource type. NSGs are
used regardless because they attach to individual resources rather than whole subnets —
matching Oracle's own recommendation in every official rule table — decoupling security
policy from network topology and keeping the rules reusable if the design changes later.

Rules below are dynamically generated and flattened from local configuration in the module,
and gated by variable flags (`enable_nodeport_public_access`, `enable_worker_ssh_access`,
`enable_pods_outbound_internet`, `enable_worker_general_outbound`) where marked *(optional)*.

### Kubernetes API Endpoint subnet

**Ingress**

| Source | Port | Description |
| --- | --- | --- |
| Worker Nodes CIDR | TCP 6443 | Worker → API endpoint communication |
| Worker Nodes CIDR | TCP 12250 | Worker → API endpoint communication |
| Pods CIDR | TCP 6443 | Pod → API endpoint communication (VCN-native) |
| Pods CIDR | TCP 12250 | Pod → API endpoint communication (VCN-native) |
| Worker Nodes CIDR | ICMP 3,4 | Path MTU Discovery |
| Team IPs *(optional)* | TCP 6443 | `kubectl` / client access — never `0.0.0.0/0` |

**Egress**

| Destination | Port | Description |
| --- | --- | --- |
| OCI Services Network | TCP 443 | API endpoint → OKE communication |
| Pods CIDR | ALL | API endpoint → pod communication (VCN-native) |
| Worker Nodes CIDR | ICMP 3,4 | Path MTU Discovery |
| Worker Nodes CIDR | TCP 10250, ICMP | API endpoint → worker node communication |

### Worker Nodes subnet

**Ingress**

| Source | Port | Description |
| --- | --- | --- |
| Worker Nodes CIDR | ALL | Communication between worker nodes |
| Pods CIDR | ALL | Pods on one node reach pods on other nodes |
| API Endpoint CIDR | TCP ALL | API endpoint → worker node communication |
| `0.0.0.0/0` | ICMP 3,4 | Path MTU Discovery |
| Load Balancer CIDR | ALL / 10256 | LB → kube-proxy health check on worker nodes |
| `0.0.0.0/0` *(optional)* | ALL / 30000–32767 | NodePort traffic via LB / Network LB (`enable_nodeport_public_access`) |

**Egress**

| Destination | Port | Description |
| --- | --- | --- |
| Worker Nodes CIDR | ALL | Communication between worker nodes |
| Pods CIDR | ALL | Worker nodes reach pods on other nodes |
| `0.0.0.0/0` | ICMP 3,4 | Path MTU Discovery |
| OCI Services Network | TCP ALL | Nodes communicate with OKE |
| API Endpoint CIDR | TCP 6443 | Worker → API endpoint communication |
| API Endpoint CIDR | TCP 12250 | Worker → API endpoint communication |
| `0.0.0.0/0` *(optional)* | TCP ALL | General outbound internet access (`enable_worker_general_outbound`) |

Optional, for troubleshooting: inbound SSH (TCP 22) to worker nodes, gated by
`enable_worker_ssh_access` and scoped to `ssh_allowed_cidr`.

### Pods subnet

**Ingress**

| Source | Port | Description |
| --- | --- | --- |
| API Endpoint CIDR | ALL | API endpoint → pod communication |
| Worker Nodes CIDR | ALL | Pods on one node reach pods on other nodes |
| Pods CIDR | ALL | Pods communicate with each other — enables the microservices to call each other |

**Egress**

| Destination | Port | Description |
| --- | --- | --- |
| Pods CIDR | ALL | Pods communicate with each other |
| OCI Services Network | ICMP 3,4 | Path MTU Discovery |
| OCI Services Network | TCP ALL | Pods communicate with OCI services |
| API Endpoint CIDR | TCP 6443 | Pod → API endpoint communication |
| API Endpoint CIDR | TCP 12250 | Pod → API endpoint communication |
| `0.0.0.0/0` *(optional)* | TCP 443 | Outbound internet access, if needed (`enable_pods_outbound_internet`) |

### Load Balancer subnet

**Ingress**

| Source | Port | Description |
| --- | --- | --- |
| `0.0.0.0/0` | TCP 443 | Public traffic to the Load Balancer |

**Egress**

| Destination | Port | Description |
| --- | --- | --- |
| Worker Nodes CIDR | ALL / 30000–32767 | LB forwards traffic to worker nodes |
| Worker Nodes CIDR | ALL / 10256 | LB communicates with kube-proxy health check |

## 5. Flow Logs

VCN flow logging is conditionally provisioned via the `enable_flow_logs` flag, demonstrating
conditional (`count`-based) resource creation — off by default to minimize log volume/cost,
enable when auditing traffic is required.

## 6. Inputs

| Variable | Type | Description |
| --- | --- | --- |
| `compartment_ocid` | `string` | OCID of the compartment to build networking resources in |
| `project_name` | `string` | Short name used as a prefix for all resources |
| `vcn_cidr` | `string` | CIDR block for the VCN |
| `subnets` | `map(object)` | Map of subnet name → config, covering API endpoint, load balancer, worker nodes, and pods subnets |
| `enable_nodeport_public_access` | `bool` | Allow `0.0.0.0/0` to reach worker nodes on the NodePort range (30000–32767) directly, bypassing the load balancer |
| `enable_worker_ssh_access` | `bool` | Allow inbound SSH (port 22) to worker nodes, for troubleshooting |
| `enable_pods_outbound_internet` | `bool` | Allow pods outbound internet access on 443, beyond OCI services |
| `enable_worker_general_outbound` | `bool` | Allow worker nodes general outbound internet access on all TCP ports, beyond what OKE/API/NAT requires |
| `enable_flow_logs` | `bool` | Toggle VCN flow logging on/off |

## 7. Outputs

| Output | Description |
| --- | --- |
| `vcn_id` | The OCID of the main Virtual Cloud Network |
| `subnet_ids` | Map of subnet names to their respective OCIDs (e.g. `subnet_ids["worker_nodes"]`) |
| `nsg_ids` | Map of NSG names to their respective OCIDs (e.g. `nsg_ids["worker_nodes"]`) |
| `api_endpoint_subnet_id` | The OCID of the API endpoint subnet |
| `load_balancer_subnet_id` | The OCID of the load balancer subnet |
| `worker_nodes_subnet_id` | The OCID of the worker nodes subnet |
| `pods_subnet_id` | The OCID of the pods subnet |

This module is designed to be consumed by the [`oke` module](../oke/README.md), which takes
its `vcn_id`, subnet IDs, and NSG IDs as inputs to provision the cluster and node pool.