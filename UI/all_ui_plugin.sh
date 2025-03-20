oc apply -f - <<EOF
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: user1-viewer-dashboard
  namespace: openshift-cluster-observability-operator
subjects:
  - kind: User
    apiGroup: rbac.authorization.k8s.io
    name: user1
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: persesdashboard-viewer-role

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: user1-viewer-datasource
  namespace: openshift-cluster-observability-operator
subjects:
  - kind: User
    apiGroup: rbac.authorization.k8s.io
    name: user1
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: persesdatasource-viewer-role
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: user1-editor-dashboard
subjects:
  - kind: User
    apiGroup: rbac.authorization.k8s.io
    name: user1
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: persesdashboard-editor-role

kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: user1-editor-datasource
subjects:
  - kind: User
    apiGroup: rbac.authorization.k8s.io
    name: user1
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: persesdatasource-editor-role
---
apiVersion: observability.openshift.io/v1alpha1
kind: UIPlugin
metadata:
  name: monitoring
spec:
  type: Monitoring
  monitoring:
    acm:
      enabled: true
      alertmanager:
        url: 'https://alertmanager.open-cluster-management-observability.svc:9095'
      thanosQuerier:
        url: 'https://rbac-query-proxy.open-cluster-management-observability.svc:8443'
    perses:
      enabled: true
    incidents:
      enabled: true
---
apiVersion: observability.openshift.io/v1alpha1
kind: UIPlugin
metadata:
  name: troubleshooting-panel
spec:
  type: TroubleshootingPanel
EOF
