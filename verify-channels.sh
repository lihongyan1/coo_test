#!/bin/bash
set -eu

function log_cmd() {
    echo "\$ $*"
    "$@"
}

# the path to the SQLite db changed in OCP v4.11
for ocp_version in 4.12 4.13 4.14 4.15 ; do
    echo "*OCP $ocp_version*"
    echo "{noformat}"
    log_cmd opm alpha list bundles registry.stage.redhat.io/redhat/redhat-operator-index:v$ocp_version cluster-observability-operator
    echo "{noformat}"
    echo
done
