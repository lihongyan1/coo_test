oc apply -f - <<EOF
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: icsp-coo
spec:
  repositoryDigestMirrors:
  - mirrors:
    - ec2-18-221-187-83.us-east-2.compute.amazonaws.com:6001/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator
    source: registry.redhat.io/cluster-observability-operator
EOF
