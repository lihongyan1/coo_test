oc apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-operator-COO-1327-workaround
rules:
- apiGroups:
  - events.k8s.io
  resources:
  - events
  verbs:
  - patch
  - create
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-operator-coo-1327-workaround-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus-operator-COO-1327-workaround
subjects:
- kind: ServiceAccount
  name: obo-prometheus-operator
  namespace: openshift-cluster-observability-operator
EOF
