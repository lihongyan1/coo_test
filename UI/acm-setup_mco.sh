#!/bin/bash
set -eux
oc patch Scheduler cluster --type='json' -p '[{ "op": "replace", "path": "/spec/mastersSchedulable", "value": true }]'

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
EOF
tries=30
while [[ $tries -gt 0 ]] &&
	! oc -n open-cluster-management rollout status deploy/multiclusterhub-operator; do
	sleep 10
	((tries--))
done
oc wait -n open-cluster-management --for=condition=Available deploy/multiclusterhub-operator --timeout=300s
oc apply -f - <<EOF
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  name: multiclusterhub
  namespace: open-cluster-management
spec: {}
EOF
sleep 5m
oc wait -n open-cluster-management --for=condition=Available deploy/search-api --timeout=300s
oc wait -n open-cluster-management --for=condition=Available deploy/search-collector --timeout=300s
oc wait -n open-cluster-management --for=condition=Available deploy/search-indexer --timeout=300s
oc -n open-cluster-management get pod
#create multi-cluster
oc create ns open-cluster-management-observability
oc apply -k ~/projects/multicluster-observability-operator/examples/minio
oc wait -n open-cluster-management-observability --for=condition=Available deploy/minio --timeout=300s
oc apply -f - <<EOF
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  name: observability
spec:
  observabilityAddonSpec: {}
  storageConfig:
    metricObjectStorage:
      name: thanos-object-storage
      key: thanos.yaml 
EOF
sleep 1m
oc wait --for=condition=Ready pod -l alertmanager=observability,app=multicluster-observability-alertmanager -n open-cluster-management-observability --timeout=300s
oc -n open-cluster-management-observability get pod
oc -n open-cluster-management-observability get svc | grep -E 'alertmanager|rbac-query'
