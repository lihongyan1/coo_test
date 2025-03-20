#!/bin/bash
set -eux -o pipefail

#Get token from https://console-openshift-console.apps.ci.l2s4.p1.openshiftapps.com
TOKEN=sha256~awpl4SRG-UJCWAuikI8G1VKaKaFSYr-gNJqXxwMLzLw
GANGWAY_API='https://gangway-ci.apps.ci.l2s4.p1.openshiftapps.com'

# Get job name
PROW_JOBS=$(cat ~/projects/ci/release/ci-operator/jobs/rhobs/observability-operator/rhobs-observability-operator-main-periodics.yaml| grep -i name | grep -i coo-stage | awk -F:" " '{print $2}')

# Echo jobs
echo $PROW_JOBS

# Trigger job
#for JOB_NAME in $PROW_JOBS; do echo $JOB_NAME; curl -X POST -d '{"job_execution_type": "1", "pod_spec_options": { "envs": {"COO_INDEX_IMAGE": "quay.io/redhat-user-workloads/cluster-observabilit-tenant/coo-fbc-v4-17:on-pr-c8e60cd924784337e6d57659f8276ce2ec2b42c7"} } }'  -H "Authorization: Bearer ${TOKEN}" "${GANGWAY_API}/v1/executions/${JOB_NAME}"; done

# Trigger single job
JOB_NAME='periodic-ci-rhobs-observability-operator-main-ocp-4.17-coo-stage'
curl -X POST -d '{"job_execution_type": "1", "pod_spec_options": { "envs": {"COO_INDEX_IMAGE": "registry.stage.redhat.io/rh-osbs/iib@sha256:a376b32985af83cc4882d1952a41b08ba4324511b22e32718f419f9406606360"} } }' -H "Authorization: Bearer ${TOKEN}" "${GANGWAY_API}/v1/executions/${JOB_NAME}"

#Trigger single job after konflux integration
curl -X POST -d '{
 "job_execution_type": "1",
 "pod_spec_options": {
  "envs": {
   "MULTISTAGE_PARAM_OVERRIDE_OTEL_INDEX_IMAGE": "brew.registry.redhat.io/rh-osbs/iib:986879"
  }
 }
}' -H "Authorization: Bearer ${TOKEN}" "${GANGWAY_API}/v1/executions/${JOB_NAME}"
