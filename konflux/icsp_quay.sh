cat <<EOF|oc create -f -
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: icsp-stage-coo
spec:
  repositoryDigestMirrors:
  - mirrors:
    - quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator
    source: registry.redhat.io/cluster-observability-operator
EOF

