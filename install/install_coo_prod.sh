#!/bin/bash
set -eux
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-observability-operator
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  namespace: openshift-observability-operator
  name: og-global
  labels:
    og_label: openshift-observability-operator
spec:
EOF

oc apply -f - <<EOF
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/observability-operator.openshift-operators: ""
  name: cluster-observability-operator
  namespace: openshift-observability-operator
spec:
  channel: development
  installPlanApproval: Automatic
  name: cluster-observability-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

