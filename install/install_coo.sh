#!/bin/bash
set -eux
#IIB=brew.registry.redhat.io/rh-osbs/iib-pub-pending:v4.17
#IIB=brew.registry.redhat.io/rh-osbs/iib:836889
#IIB=registry.redhat.io/redhat/redhat-operator-index:v4.18
#IIB=quay.io/redhat-user-workloads/cluster-observabilit-tenant/coo-fbc-v4-17@sha256:9be32b5753753a3db1c051aa3c26d4acc8a5ac54d32c74b77c80c94f8b3b94a6
IIB=quay.io/redhat-user-workloads/cluster-observabilit-tenant/coo-fbc-v4-17@sha256:c429d46fa0258fbed20bb2f2454484926bfc0773202b0246eccd1ba75cd9e9aa
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
  name: cluster-observability-operator
  namespace: openshift-cluster-observability-operator
spec:
  channel: stable
  installPlanApproval: Automatic
  name: cluster-observability-operator
  source: coo
  sourceNamespace: openshift-marketplace
EOF

