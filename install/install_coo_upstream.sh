#!/bin/bash
set -eux

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/install_utils.sh"

IIB=quay.io/rhobs/observability-operator-catalog:latest
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
    operators.coreos.com/observability-operator.openshift-operators: ""
  name: observability-operator
  namespace: openshift-cluster-observability-operator
spec:
  channel: stable
  installPlanApproval: Automatic
  name: observability-operator
  source: coo
  sourceNamespace: openshift-marketplace
EOF
# Wait for operator to be ready
wait_for_operator "openshift-cluster-observability-operator"
