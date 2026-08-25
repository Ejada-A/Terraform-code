# All NSG rule data lives here as locals
# Protocol codes: "6" = TCP, "1" = ICMP, "all" = all protocols.

locals {
  cidr = { for k, v in oci_core_subnet.this : k => v.cidr_block }

  oci_services_cidr = data.oci_core_services.all_services.services[0]["cidr_block"]

  #Ingress rules
  ingress_by_nsg = {

    # Kubernetes API Endpoint subnet - Ingress
    api_endpoint = concat([
      {
        description = "External access to Kubernetes API endpoint"
        protocol    = "6"
        source      = "0.0.0.0/0"
        port_min    = 6443
        port_max    = 6443
      },
      {
        description = "Worker to API endpoint communication"
        protocol    = "6"
        source      = local.cidr["worker_nodes"]
        port_min    = 6443
        port_max    = 6443
      },
      {
        description = "Worker to API endpoint communication"
        protocol    = "6"
        source      = local.cidr["worker_nodes"]
        port_min    = 12250
        port_max    = 12250
      },
      {
        description = "Pod to API endpoint communication (VCN-native)"
        protocol    = "6"
        source      = local.cidr["pods"]
        port_min    = 6443
        port_max    = 6443
      },
      {
        description = "Pod to API endpoint communication (VCN-native)"
        protocol    = "6"
        source      = local.cidr["pods"]
        port_min    = 12250
        port_max    = 12250
      },
      {
        description = "Path MTU Discovery"
        protocol    = "1"
        source      = local.cidr["worker_nodes"]
        icmp_type   = 3
        icmp_code   = 4
      }
      ],
    )

    # Load Balancer subnet - Ingress
    load_balancer = [
      {
        description = "Public HTTP traffic to the Load Balancer"
        protocol    = "6"
        source      = "0.0.0.0/0"
        port_min    = 80
        port_max    = 80
      },
      {
        description = "Public traffic to the Load Balancer"
        protocol    = "6"
        source      = "0.0.0.0/0"
        port_min    = 443
        port_max    = 443
      }
    ]

    # Worker Nodes subnet - Ingress
    worker_nodes = concat([
      {
        description = "Communication between worker nodes"
        protocol    = "all"
        source      = local.cidr["worker_nodes"]
      },
      {
        description = "Pods on one node reach pods on other nodes"
        protocol    = "all"
        source      = local.cidr["pods"]
      },
      {
        description = "API endpoint to worker node communication"
        protocol    = "6"
        source      = local.cidr["api_endpoint"]
      },
      {
        description = "Path MTU Discovery"
        protocol    = "1"
        source      = "0.0.0.0/0"
        icmp_type   = 3
        icmp_code   = 4
      },
      {
        description = "LB to kube-proxy health check on worker nodes"
        protocol    = "6"
        source      = local.cidr["load_balancer"]
        port_min    = 10256
        port_max    = 10256
      }
      ],
      var.enable_worker_ssh_access ? [{
        description = "Optional: SSH access for troubleshooting"
        protocol    = "6"
        source      = "0.0.0.0/0"
        port_min    = 22
        port_max    = 22
      }] : [],
      var.enable_nodeport_public_access ? [{
        description = "Optional: NodePort traffic via LB / Network LB"
        protocol    = "6"
        source      = "0.0.0.0/0"
        port_min    = 30000
        port_max    = 32767
      }] : []
    )

    # Pods subnet - Ingress
    pods = [
      {
        description = "API endpoint to pod communication"
        protocol    = "all"
        source      = local.cidr["api_endpoint"]
      },
      {
        description = "Pods on one node reach pods on other nodes"
        protocol    = "all"
        source      = local.cidr["worker_nodes"]
      },
      {
        description = "Pods communicate with each other - enables the 4 microservices to call each other"
        protocol    = "all"
        source      = local.cidr["pods"]
      }
    ]
  }

  #Egress rules
  egress_by_nsg = {

    # Kubernetes API Endpoint subnet - Egress
    api_endpoint = [
      {
        description = "API endpoint to OKE communication"
        protocol    = "6"
        destination = local.oci_services_cidr
        port_min    = 443
        port_max    = 443
      },
      {
        description = "API endpoint to pod communication (VCN-native)"
        protocol    = "all"
        destination = local.cidr["pods"]
      },
      {
        description = "Path MTU Discovery"
        protocol    = "1"
        destination = local.cidr["worker_nodes"]
        icmp_type   = 3
        icmp_code   = 4
      },
      {
        description = "API endpoint to worker node communication"
        protocol    = "6"
        destination = local.cidr["worker_nodes"]
        port_min    = 10250
        port_max    = 10250
      },
      {
        description = "API endpoint to worker node communication (ICMP)"
        protocol    = "1"
        destination = local.cidr["worker_nodes"]
      }
    ]

    # Load Balancer subnet - Egress
    load_balancer = [
      {
        description = "LB forwards traffic to worker nodes (NodePort range)"
        protocol    = "6"
        destination = local.cidr["worker_nodes"]
        port_min    = 30000
        port_max    = 32767
      },
      {
        description = "LB communicates with kube-proxy health check"
        protocol    = "6"
        destination = local.cidr["worker_nodes"]
        port_min    = 10256
        port_max    = 10256
      }
    ]

    # Worker Nodes subnet - Egress
    worker_nodes = concat([
      {
        description = "Communication between worker nodes"
        protocol    = "all"
        destination = local.cidr["worker_nodes"]
      },
      {
        description = "Worker nodes reach pods on other nodes"
        protocol    = "all"
        destination = local.cidr["pods"]
      },
      {
        description = "Path MTU Discovery"
        protocol    = "1"
        destination = "0.0.0.0/0"
        icmp_type   = 3
        icmp_code   = 4
      },
      {
        description = "Nodes communicate with OKE"
        protocol    = "6"
        destination = local.oci_services_cidr
      },
      {
        description = "Worker to API endpoint communication"
        protocol    = "6"
        destination = local.cidr["api_endpoint"]
        port_min    = 6443
        port_max    = 6443
      },
      {
        description = "Worker to API endpoint communication"
        protocol    = "6"
        destination = local.cidr["api_endpoint"]
        port_min    = 12250
        port_max    = 12250
      }
      ],
      var.enable_worker_general_outbound ? [{
        description = "Optional: general outbound internet access"
        protocol    = "6"
        destination = "0.0.0.0/0"
      }] : []
    )

    # Pods subnet - Egress
    pods = concat([
      {
        description = "Pods communicate with each other"
        protocol    = "all"
        destination = local.cidr["pods"]
      },
      {
        description = "Path MTU Discovery"
        protocol    = "1"
        destination = local.oci_services_cidr
        icmp_type   = 3
        icmp_code   = 4
      },
      {
        description = "Pods communicate with OCI services"
        protocol    = "6"
        destination = local.oci_services_cidr
      },
      {
        description = "Pod to API endpoint communication"
        protocol    = "6"
        destination = local.cidr["api_endpoint"]
        port_min    = 6443
        port_max    = 6443
      },
      {
        description = "Pod to API endpoint communication"
        protocol    = "6"
        destination = local.cidr["api_endpoint"]
        port_min    = 12250
        port_max    = 12250
      }
      ],
      var.enable_pods_outbound_internet ? [{
        description = "Optional: outbound internet access, if needed"
        protocol    = "6"
        destination = "0.0.0.0/0"
        port_min    = 443
        port_max    = 443
      }] : []
    )
  }

  # Flatten "nsg key + rule index" pairs so we can for_each over a flat map
  ingress_rules_flat = merge([
    for nsg_key, rules in local.ingress_by_nsg : {
      for idx, rule in rules :
      "${nsg_key}-${idx}" => merge(rule, { nsg_key = nsg_key })
    }
  ]...)

  egress_rules_flat = merge([
    for nsg_key, rules in local.egress_by_nsg : {
      for idx, rule in rules :
      "${nsg_key}-${idx}" => merge(rule, { nsg_key = nsg_key })
    }
  ]...)
}
