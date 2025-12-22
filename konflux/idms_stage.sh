cat <<EOF|oc apply -f -
apiVersion: config.openshift.io/v1
kind: ImageDigestMirrorSet
metadata:
  name: idms-stage-coo
spec:
  imageDigestMirrors:
  - mirrors:
    - registry.stage.redhat.io
    source: registry.redhat.io
  - mirrors:
    - brew.registry.redhat.io/rh-osbs/iib
    source: registry-proxy.engineering.redhat.com/rh-osbs/iib
EOF
