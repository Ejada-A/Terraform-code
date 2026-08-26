#!/bin/bash
# =============================================================================
# export_kubeconfig.sh
# Generates and distributes kubeconfig for OKE cluster contributors.
# Usage: ./scripts/export_kubeconfig.sh <CLUSTER_OCID> [REGION]
# =============================================================================

set -euo pipefail

CLUSTER_OCID="${1:?ERROR: CLUSTER_OCID (arg 1) is required.}"
REGION="${2:-me-jeddah-1}"
KUBECONFIG_PATH="${HOME}/.kube/config"

echo "=================================================="
echo "🔑 Generating kubeconfig for OKE cluster"
echo "Cluster OCID: $CLUSTER_OCID"
echo "Region:       $REGION"
echo "Output:       $KUBECONFIG_PATH"
echo "=================================================="

mkdir -p "$(dirname "$KUBECONFIG_PATH")"

# Generate kubeconfig via OCI CLI (uses your locally configured OCI CLI credentials)
oci ce cluster create-kubeconfig \
  --cluster-id "$CLUSTER_OCID" \
  --file "$KUBECONFIG_PATH" \
  --region "$REGION" \
  --token-version 2.0.0 \
  --kube-endpoint PUBLIC_ENDPOINT

echo ""
echo "✅ kubeconfig written to $KUBECONFIG_PATH"
echo ""

# Verify connection
echo "🔍 Verifying cluster connection..."
kubectl cluster-info
kubectl get nodes
echo ""
echo "✅ Cluster connection successful!"
echo ""
echo "📌 Share instructions for contributors:"
echo "   1. Install OCI CLI: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
echo "   2. Configure OCI CLI: oci setup config"
echo "   3. Run: ./scripts/export_kubeconfig.sh <CLUSTER_OCID> [REGION]"
echo ""
