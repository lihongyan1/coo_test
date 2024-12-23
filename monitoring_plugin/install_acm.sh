#!/bin/bash
set -eux
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: open-cluster-management
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  namespace: open-cluster-management
  name: og-global
  labels:
    og_label: open-cluster-management
spec:
  targetNamespaces:
  - open-cluster-management
  upgradeStrategy: Default
EOF
oc apply -f - <<EOF
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/advanced-cluster-management.open-cluster-management: ""
  name: advanced-cluster-management
  namespace: open-cluster-management
spec:
  installPlanApproval: Automatic
  name: advanced-cluster-management
  source: redhat-operators
  sourceNamespace: openshift-marketplace
---
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  name: multiclusterhub
  namespace: open-cluster-management
spec: {}
EOF

