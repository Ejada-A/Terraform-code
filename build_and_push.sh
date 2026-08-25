#!/bin/bash
set -e

# ==============================================================================
# Build & Push Microservices Images to OCIR (Oracle Container Registry)
# ==============================================================================

REGION="${1:-jed.ocir.io}"                    # e.g. jed.ocir.io, iad.ocir.io
TENANCY_NAMESPACE="${2:-axkjllkftxfz}"       # OCI Tenancy Namespace
TAG="${3:-latest}"
REPO_PREFIX="${4:-shared-group-a-cmp}"                         # Optional: Compartment path or prefix (e.g. "my-compartment" or "ejada")

PROJECT_DIR="/home/ali_hamad/terraform/Project"

echo "================================================="
echo "🚀 Building and Pushing Microservices to OCIR"
echo "Region:            ${REGION}"
echo "Tenancy Namespace: ${TENANCY_NAMESPACE}"
echo "Tag:               ${TAG}"
if [ -n "${REPO_PREFIX}" ]; then
  echo "Repo Prefix/Folder:${REPO_PREFIX}"
fi
echo "================================================="

if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker daemon is not running or current user lacks permissions."
    exit 1
fi

# Define service names
SERVICES=("auth-service" "products-service" "orders-service" "payments-service" "ecomm-ui")

for SERVICE in "${SERVICES[@]}"; do
    # Determine image path (with compartment/prefix if supplied)
    if [ -n "${REPO_PREFIX}" ]; then
        IMAGE_NAME="${REGION}/${TENANCY_NAMESPACE}/${REPO_PREFIX}/${SERVICE}:${TAG}"
    else
        IMAGE_NAME="${REGION}/${TENANCY_NAMESPACE}/${SERVICE}:${TAG}"
    fi

    SERVICE_PATH="${PROJECT_DIR}/${SERVICE}"

    echo ""
    echo "-------------------------------------------------"
    echo "📦 Building Docker image for ${SERVICE}..."
    echo "Path:  ${SERVICE_PATH}"
    echo "Image: ${IMAGE_NAME}"
    echo "-------------------------------------------------"

    docker build -t "${IMAGE_NAME}" "${SERVICE_PATH}"

    echo "-------------------------------------------------"
    echo "⬆️  Pushing image ${IMAGE_NAME} to OCIR..."
    echo "-------------------------------------------------"

    docker push "${IMAGE_NAME}"

    echo "✅ Successfully built and pushed ${SERVICE}!"
done

echo ""
echo "================================================="
echo "🎉 All 5 microservices successfully pushed to OCIR!"
echo "================================================="
