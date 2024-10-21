#!/bin/bash

ID=$1
source "./pre_set.sh"
curl -X GET -H "Authorization: Bearer ${TOKEN}"  ${GANGWAY_API}/v1/executions/${ID}

