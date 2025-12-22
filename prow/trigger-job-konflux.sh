#!/bin/bash
set -eux -o pipefail

GANGWAY_API_TOKEN=${GANGWAY_API_TOKEN}
GANGWAY_API='https://gangway-ci.apps.ci.l2s4.p1.openshiftapps.com'

curl -X POST -d '{
 "job_execution_type": "1",
 "pod_spec_options": {
  "envs": {
   "MULTISTAGE_PARAM_OVERRIDE_OTEL_INDEX_IMAGE": "brew.registry.redhat.io/rh-osbs/iib:986879"
  }
 }
}' -H "Authorization: Bearer ${TOKEN}" "${GANGWAY_API}/v1/executions/${JOB_NAME}"
