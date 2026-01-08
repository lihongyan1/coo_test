#!/bin/bash
set -e

# Script to mirror Cluster Observability Operator to a disconnected registry
# Usage: ./mirror_prod_operator.sh [MIRROR_REGISTRY] [OCP_VERSION]
#
# Examples:
#   ./mirror_prod_operator.sh
#   ./mirror_prod_operator.sh ec2-3-148-245-234.us-east-2.compute.amazonaws.com:5000
#   ./mirror_prod_operator.sh ec2-3-148-245-234.us-east-2.compute.amazonaws.com:5000 v4.22

# Configuration
DEFAULT_MIRROR_REGISTRY="ec2-3-148-245-234.us-east-2.compute.amazonaws.com:5000"
DEFAULT_OCP_VERSION="v4.21"

MIRROR_REGISTRY="${1:-$DEFAULT_MIRROR_REGISTRY}"
OCP_VERSION="${2:-$DEFAULT_OCP_VERSION}"
WORKSPACE="${PWD}/data_mirror_result"

# Validate environment
echo "Checking environment..."
if [[ -z "$MIRROR_REGISTRY" ]]; then
    echo "Error: Mirror registry must be provided"
    exit 1
fi

# Check required commands
for cmd in podman oc-mirror; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed or not in PATH"
        exit 1
    fi
done

echo "Mirror Registry: $MIRROR_REGISTRY"
echo "OCP Version: $OCP_VERSION"
echo "Workspace: $WORKSPACE"

# Create workspace directory
if [[ -d "$WORKSPACE" ]]; then
    echo "Warning: Workspace directory already exists: $WORKSPACE"
    read -p "Do you want to remove it and continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$WORKSPACE"
        echo "Removed existing workspace"
    else
        echo "Aborted by user"
        exit 1
    fi
fi

mkdir -p "$WORKSPACE" || {
    echo "Error: Failed to create workspace directory"
    exit 1
}

# Login to registries
echo "Logging into mirror registry: $MIRROR_REGISTRY"
podman login --tls-verify=false "$MIRROR_REGISTRY" || {
    echo "Error: Failed to login to mirror registry"
    exit 1
}

echo "Logging into registry.redhat.io"
podman login registry.redhat.io || {
    echo "Error: Failed to login to registry.redhat.io"
    echo "Please ensure you have valid Red Hat registry credentials"
    exit 1
}

# Create ImageSet configuration
echo "Creating ImageSet configuration..."
cat <<EOF >"${WORKSPACE}/imageset.yaml"
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
mirror:
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:${OCP_VERSION}
    packages:
    - name: cluster-observability-operator
      channels:
      - name: stable
EOF

echo "ImageSet configuration created at: ${WORKSPACE}/imageset.yaml"
cat "${WORKSPACE}/imageset.yaml"

# Run oc-mirror
echo "Starting mirror process..."
echo "This may take several minutes depending on your network connection..."

oc-mirror --v2 \
    --config "${WORKSPACE}/imageset.yaml" \
    --workspace "file://${WORKSPACE}" \
    "docker://${MIRROR_REGISTRY}" || {
    echo "Error: Mirror process failed"
    exit 1
}

# Show results
echo ""
echo "Mirror process completed successfully!"
echo ""
echo "Cluster resources have been generated at:"
echo "  ${WORKSPACE}/working-dir/cluster-resources/"
echo ""

if [[ -d "${WORKSPACE}/working-dir/cluster-resources/" ]]; then
    echo "Generated files:"
    ls -lh "${WORKSPACE}/working-dir/cluster-resources/"
    echo ""
fi

# Instructions
cat <<EOF
Next Steps:
===========
1. Apply the ImageDigestMirrorSet (IDMS):
   oc apply -f ${WORKSPACE}/working-dir/cluster-resources/idms-*.yaml

2. Apply the CatalogSource:
   oc apply -f ${WORKSPACE}/working-dir/cluster-resources/cs-*.yaml

3. Wait for the MachineConfigPool to update (if IDMS was applied):
   oc get mcp

4. Verify the CatalogSource is ready:
   oc get catalogsource -n openshift-marketplace

5. Install the operator from OperatorHub or create a Subscription

Note: For disconnected clusters, ensure the ImageContentSourcePolicy or
ImageDigestMirrorSet is applied and nodes are rebooted before installing.
EOF
