cat <<EOF|oc create -f -
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: icsp-stage-coo
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.stage.redhat.io
    source: registry.redhat.io
  - mirrors:
    - brew.registry.redhat.io/rh-osbs/iib
    source: registry-proxy.engineering.redhat.com/rh-osbs/iib
EOF

