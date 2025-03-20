#!/bin/bash
set -eux -o pipefail

#Can also check job results from UI: https://prow.ci.openshift.org/

ID=$1
source "./pre_set.sh"
curl -X GET -H "Authorization: Bearer ${TOKEN}"  ${GANGWAY_API}/v1/executions/${ID}

