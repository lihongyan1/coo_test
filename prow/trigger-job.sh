#!/bin/bash
set -eux -o pipefail

#Get token from https://console-openshift-console.apps.ci.l2s4.p1.openshiftapps.com
TOKEN=${GANGWAY_API_TOKEN}
GANGWAY_API='https://gangway-ci.apps.ci.l2s4.p1.openshiftapps.com'

# Get job name
PROW_JOBS=$(cat ~/projects/ci/release/ci-operator/jobs/rhobs/observability-operator/rhobs-observability-operator-main-periodics.yaml| grep -i name | grep -i coo-stage | awk -F:" " '{print $2}')

# Echo jobs
echo $PROW_JOBS

# Trigger job
for JOB_NAME in $PROW_JOBS; do echo $JOB_NAME; curl -X POST -d '{"job_execution_type": "1"}' -H "Authorization: Bearer ${TOKEN}" "${GANGWAY_API}/v1/executions/${JOB_NAME}"; done

# Trigger single job
#JOB_NAME='periodic-ci-rhobs-observability-operator-main-ocp-4.14-coo-stage'
#curl -X POST -d '{"job_execution_type": "1"}' -H "Authorization: Bearer ${TOKEN}" "${GANGWAY_API}/v1/executions/${JOB_NAME}"
