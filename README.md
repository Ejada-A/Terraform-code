# OCI Kubernetes & Microservices Infrastructure Project

Terraform root orchestrator for a complete, VCN-native Oracle Kubernetes Engine (OKE)
environment on Oracle Cloud Infrastructure (OCI), built to host a 4-microservice
e-commerce application (`auth`, `products`, `cart`/`orders`, `payments`).

This module wires together the [`network`](./modules/network/README.md) and [`oke`](./modules/oke/README.md)
child modules, resolves the latest Oracle Linux 8 image for the chosen compute shape, and
provisions the OCIR container repositories for each microservice — turning a set of
input variables into a ready-to-use cluster with `kubectl` access.

---

## 1. Architecture at a Glance

The application is split into 4 domains, each mapped 1:1 to its own microservice:

| Domain | Owns | Depends on |
| --- | --- | --- |
| **Auth** | User accounts, credentials, roles (`admin`, `user`) | Nothing |
| **Product** | Catalog: name, description, price, stock, images | Auth (admin role for create/update/delete; user role for view) |
| **Cart** | Cart items, quantities, owning user | Auth (must be `user` role — admins are blocked) + Product (existence, stock, price) |
| **Purchase** | Orders, transactions, payment records, receipts | Auth (`user` role only) + Cart (items/qty) + Product (final price/stock at purchase time) |

Admin CRUD-on-products is folded into the **Product** domain rather than split out, since a
domain is defined by the data it owns, not by who is allowed to touch it. **Cart** and
**Purchase** are kept as fully separate services (not merged) because Cart is temporary,
high-churn data hit constantly, while Purchase is permanent, immutable financial data that
is hit rarely but must prioritize reliability over speed — mixing them risks Cart bugs
corrupting financial records.

Each microservice is:
- **Stateless at the pod level**, scaled independently via its own Horizontal Pod Autoscaler.
- **Backed by its own database** (database-per-service), isolated from the others.
- **Routed to** via a single public Load Balancer and Ingress Controller using path-based rules.
- **Built and pushed** to its own dedicated OCIR repository.

```
Internet
   │
   ▼
[Load Balancer subnet] ── OCI Load Balancer ── Ingress Controller
   │
   ├── /api/auth/*      → Auth service      (+ Auth DB)
   ├── /api/products/*  → Product service   (+ Product DB)
   ├── /api/cart/*      → Cart service      (+ Cart DB)
   └── /api/purchase/*  → Purchase service  (+ Purchase DB)

[Worker Nodes subnet]  — private — hosts all pods
[Pods subnet]          — private — VCN-native pod IPs (2nd VNIC per node)
[API Endpoint subnet]  — public  — kubectl access, restricted to known team IPs
```

## 2. Module Structure

| Module | Responsibility |
| --- | --- |
| `network` | VCN, 4 subnets, Internet/NAT/Service gateways, route tables, NSGs, optional flow logs |
| `oke` | OKE cluster, node pool, VCN-native pod networking, NSG attachment |
| *(this root module)* | Wires `network` → `oke`, resolves the Oracle Linux image |

## 3. Compute Sizing

| Item | Decision |
| --- | --- |
| Node shape | `VM.Standard.A1.Flex` (ARM, Always Free eligible) by default — configurable via `node_shape` |
| Node count | Minimum **2** worker nodes regardless of final sizing, so pod replicas get real node-level redundancy |
| OCPU / memory | Configurable via `node_ocpus` / `node_memory_in_gbs` (defaults: 2 OCPU / 16 GB) |

## 4. Scaling Strategy (HPA)

Every microservice scales independently between a min and max replica count rather than a
fixed count, keeping the environment small and low-cost for realistic project-scale traffic
while still demonstrating production-grade elasticity:

| Service | Min | Max | Reasoning |
| --- | --- | --- | --- |
| Auth | 1 | 3 | Every request depends on it — needs headroom under load |
| Product | 1 | 3 | Constant read traffic from browsing |
| Cart | 1 | 2 | Frequent traffic, but tolerant of brief unavailability |
| Purchase | 2 | 3 | Financial data — never allowed to run on a single replica |

## 5. Storage

- **Database-per-service**: 4 independent databases, no data sharing across services.
- Each database persists via its own PVC (Block Volume).
- Isolation rationale: Purchase's permanent financial records must never be exposed to
  Cart's high-churn, temporary data.
- Specific database engine is left as an implementation detail per service.

## 6. Security Summary

| Area | Design decision |
| --- | --- |
| Network isolation | Only the Load Balancer subnet is public-facing; Worker Nodes and Pods subnets are private |
| Access control | NSGs (not Security Lists) for granular, per-resource rules — see [`network` module](./modules/network/README.md) |

## 7. Prerequisites

- Terraform, with the OCI provider `>= 5.30.0`
- An OCI tenancy with API key credentials
- An SSH key pair (for optional worker node troubleshooting access)

## 8. Inputs

| Variable | Type | Description | Default |
| --- | --- | --- | --- |
| `tenancy_ocid` | `string` | The OCID of the OCI Tenancy | required |
| `compartment_ocid` | `string` | The OCID of the compartment where resources will be created | required |
| `user_ocid` | `string` | The OCID of the OCI user | required |
| `fingerprint` | `string` | The fingerprint of the OCI API key | required |
| `private_key_path` | `string` | The path to the OCI API private key file | required |
| `region` | `string` | The OCI region (e.g. `us-ashburn-1`) | required |
| `project_name` | `string` | Project name used as a prefix for resources | `"groupa"` |
| `environment` | `string` | Deployment environment (e.g. `dev`, `prod`) | `"dev"` |
| `ssh_public_key` | `string` | SSH public key for worker node access (troubleshooting) | required |
| `ssh_allowed_cidr` | `string` | CIDR block allowed to SSH into worker nodes | `"0.0.0.0/0"` |
| `node_shape` | `string` | Compute shape for OKE worker nodes | `"VM.Standard.A1.Flex"` |
| `node_ocpus` | `number` | OCPUs per worker node (Flex shapes) | `2` |
| `node_memory_in_gbs` | `number` | Memory in GB per worker node (Flex shapes) | `16` |
| `node_count` | `number` | Worker nodes per availability domain (minimum 2 enforced) | `2` |

## 9. Outputs

| Output | Description |
| --- | --- |
| `cluster_id` | The OCID of the OKE Cluster |
| `cluster_endpoint` | The public endpoint for the Kubernetes API |
| `ocir_repositories` | The created OCIR repositories, one per microservice (`groupa-auth-app`, `groupa-product-app`, `groupa-cart-app`, `groupa-purchase-app`) |
| `kubeconfig_command` | OCI CLI command to generate your local kubeconfig |

## 10. Usage

```bash
terraform init
terraform plan
terraform apply

# Once applied:
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

## 11. Notes on Kubernetes Version

The cluster is provisioned with Kubernetes `v1.34.2` and a publicly accessible API endpoint
(access to which should be locked down to known team IPs via `ssh_allowed_cidr` /
NSG rules rather than left open — see the network module for details).

