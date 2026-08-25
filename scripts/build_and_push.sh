#!/bin/bash
set -euo pipefail

# ==============================================================================
# Build & Push Microservices Images to OCIR (Oracle Container Registry)
# Usage: ./build_and_push.sh <REGION> <NAMESPACE> <TAG> <REPO_PREFIX> <SERVICES_DIR>
# All arguments are required - no hardcoded defaults.
# ==============================================================================

REGION="${1:?ERROR: REGION (arg 1) is required. e.g. jed.ocir.io}"
TENANCY_NAMESPACE="${2:?ERROR: TENANCY_NAMESPACE (arg 2) is required. e.g. axkjllkftxfz}"
TAG="${3:?ERROR: TAG (arg 3) is required. e.g. latest or git commit SHA}"
REPO_PREFIX="${4:?ERROR: REPO_PREFIX (arg 4) is required. e.g. shared-group-a-cmp}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# SERVICES_DIR: directory containing each <service-name>/ folder.
# Defaults to two levels up from scripts/ (i.e. Project/) for local use.
# In CI, pass the checked-out services workspace directory as argument 5.
SERVICES_DIR="${5:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

echo "================================================="
echo "🚀 Building and Pushing Microservices to OCIR"
echo "Region:            ${REGION}"
echo "Tenancy Namespace: ${TENANCY_NAMESPACE}"
echo "Tag:               ${TAG}"
echo "Repo Prefix:       ${REPO_PREFIX}"
echo "Services Dir:      ${SERVICES_DIR}"
echo "================================================="

if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker daemon is not running or current user lacks permissions."
    exit 1
fi

SERVICES=("auth-service" "products-service" "orders-service" "payments-service" "ecomm-ui")

for SERVICE in "${SERVICES[@]}"; do
    IMAGE_NAME="${REGION}/${TENANCY_NAMESPACE}/${REPO_PREFIX}/${SERVICE}:${TAG}"
    SERVICE_PATH="${SERVICES_DIR}/${SERVICE}"

    if [ ! -d "${SERVICE_PATH}" ]; then
        echo "❌ Error: Service directory not found: ${SERVICE_PATH}"
        exit 1
    fi

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
