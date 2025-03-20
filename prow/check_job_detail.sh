#!/bin/bash
set -eux -o pipefail
ID=$1
source "./pre_set.sh"
#https://qe-private-deck-ci.apps.ci.l2s4.p1.openshiftapps.com/prowjob?prowjob=${ID}
curl -v -X GET -H "Authorization: Bearer ${TOKEN}"  ${GANGWAY_API}/prowjob?prowjob=${ID}

