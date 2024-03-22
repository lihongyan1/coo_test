#!/bin/bash
set -eu

function log_cmd() {
    echo "\$ $*"
    "$@"
}
function exit_error() {
    >&2 echo -e "ERROR: $*"
    exit 1
}


echo "*COO image Details*"
echo

coo_images=$(oc get deployment -n openshift-operators -o yaml | grep -o "registry.redhat.io/cluster-observability-operator/.*" | sort | uniq |sed 's/registry.redhat.io/registry.stage.redhat.io/')

[ $(echo "$coo_images" | wc -l) -eq 7 ] || exit_error "Expected 7777777 images, found:\n$coo_images"

echo "{noformat}"
for image in $coo_images; do
    podman pull "$image" -q > /dev/null
    podman images "$image" --digests
done
podman image rm -a
echo "{noformat}"
