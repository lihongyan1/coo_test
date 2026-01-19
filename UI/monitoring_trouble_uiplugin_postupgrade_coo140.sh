oc apply -f - <<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: user1-persesglobaldatasource-viewer
subjects:
  - kind: User
    apiGroup: rbac.authorization.k8s.io
    name: user1
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: persesglobaldatasource-viewer-role
EOF

oc apply -f - <<EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: user2-persesglobaldatasource-viewer
subjects:
  - kind: User
    apiGroup: rbac.authorization.k8s.io
    name: user2
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: persesglobaldatasource-viewer-role
EOF
