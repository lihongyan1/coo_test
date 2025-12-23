#!/bin/bash

# Wait for CatalogSource to be ready
# Usage: wait_for_catalogsource <catalogsource_name> <namespace>
wait_for_catalogsource() {
  local catalog_name="$1"
  local namespace="$2"

  echo "Waiting for CatalogSource '$catalog_name' to be ready..."

  local tries=30
  while [[ $tries -gt 0 ]]; do
    STATE=$(oc get catalogsource "$catalog_name" -n "$namespace" -o jsonpath='{.status.connectionState.lastObservedState}' 2>/dev/null || echo "")
    if [[ "$STATE" == "READY" ]]; then
      echo "✓ CatalogSource '$catalog_name' is READY"
      return 0
    fi
    echo "CatalogSource state: $STATE (waiting...)"
    sleep 10
    ((tries--))
  done

  echo "✗ CatalogSource '$catalog_name' failed to become ready"
  return 1
}

# Wait for operator deployment to be ready
# Usage: wait_for_operator <namespace>
wait_for_operator() {
  local namespace="$1"

  echo "Waiting for operator in namespace '$namespace' to be ready..."

  # Wait for observability-operator deployment rollout
  local tries=30
  while [[ $tries -gt 0 ]] && \
    ! oc -n "$namespace" rollout status deploy/observability-operator; do
    sleep 10
    ((tries--))
  done

  # Wait for deployment to be available
  oc wait -n "$namespace" \
    --for=condition=Available deploy/observability-operator \
    --timeout=300s

  echo "✓ Operator 'observability-operator' is READY"
}
