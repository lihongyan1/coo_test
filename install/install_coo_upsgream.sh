#!/bin/bash
set -eux
#IIB=brew.registry.redhat.io/rh-osbs/iib-pub-pending:v4.17
#IIB=brew.registry.redhat.io/rh-osbs/iib:836889
#IIB=registry.redhat.io/redhat/redhat-operator-index:v4.18
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
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: observability-operator
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  namespace: observability-operator
  name: og-global
  labels:
    og_label: observability-operator
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
  namespace: observability-operator
spec:
  channel: development
  installPlanApproval: Automatic
  name: observability-operator
  source: coo
  sourceNamespace: openshift-marketplace
EOF

