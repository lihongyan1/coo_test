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
  upgradeStrategy: Default
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/cluster-observability-operator.openshift-cluster-observability: ""
  name: cluster-observability-operator
  namespace: openshift-cluster-observability-operator
spec:
  channel: stable
  installPlanApproval: Manual
  name: cluster-observability-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: cluster-observability-operator.v1.2.2
EOF
oc patch installplan install-dd4gm -n openshift-cluster-observability-operator --type merge -p '{"spec":{"approved":true}}'
