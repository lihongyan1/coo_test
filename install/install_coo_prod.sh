#!/bin/bash
set -eux

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/install_utils.sh"

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
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# Wait for operator to be ready
wait_for_operator "openshift-cluster-observability-operator"
