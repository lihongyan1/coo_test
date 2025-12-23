#!/bin/bash
set -eux

# Usage: ./install_coo.sh [IIB_IMAGE]
# If no IIB_IMAGE is provided, uses the default value

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/install_utils.sh"

# Default IIB image (stage)
DEFAULT_IIB=registry-proxy.engineering.redhat.com/rh-osbs/iib@sha256:83873f974f6e92ff4baf27fd63ecd1e7a7add773e2875b5c5086e5caa2a63024

# Use provided IIB or default
IIB=${1:-$DEFAULT_IIB}

echo "Using IIB: ${IIB}"

# Other IIB options:
# stage
#IIB=brew.registry.redhat.io/rh-osbs/iib@sha256:7ea3d19c5c376972a64b2506a03d47923959d0cd2a6a5a302dfa69797ffd65e2
#IIB=registry.redhat.io/redhat/redhat-operator-index:v4.16
# konflux
#IIB=quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/coo-fbc-v4-20@sha256:e52d48cf8e2830b66f51aa79701907cb8aaf04a18e44d15b5e5008aeeaed2787
# disconnected cluster:
#IIB=registry.redhat.io/cluster-observability-operator/coo-fbc-v4-20@sha256:e52d48cf8e2830b66f51aa79701907cb8aaf04a18e44d15b5e5008aeeaed2787
cat <<EOF |oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name:  coo
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: ${IIB}
  publisher: Openshift QE
  updateStrategy:
    registryPoll:
      interval: 10m0s
EOF

# Wait for CatalogSource to be ready before installing operator
wait_for_catalogsource "coo" "openshift-marketplace"

echo "Installing operator..."

oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  labels:
    openshift.io/cluster-monitoring: "true"
  name: openshift-cluster-observability-operator
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  namespace: openshift-cluster-observability-operator
  name: og-global
  labels:
    og_label: openshift-cluster-observability-operator
spec:
EOF
oc apply -f - <<EOF
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/cluster-observability-operator: ""
  name: cluster-observability-operator
  namespace: openshift-cluster-observability-operator
spec:
  channel: stable
  installPlanApproval: Automatic
  name: cluster-observability-operator
  source: coo
  sourceNamespace: openshift-marketplace
EOF

# Wait for operator to be ready
wait_for_operator "openshift-cluster-observability-operator"
