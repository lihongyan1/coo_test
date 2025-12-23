#!/bin/bash

# Usage: ./uninstall.sh [upstream|downstream] [CSV_VERSION]
# Default is downstream if no parameter provided
# Default CSV version is 1.3.1

INSTALL_TYPE="${1:-downstream}"
CSV_VERSION="${2:-1.3.1}"
NAMESPACE="openshift-cluster-observability-operator"

# Set subscription and CSV names based on install type
if [ "$INSTALL_TYPE" = "upstream" ]; then
  SUB_NAME="observability-operator"
  CSV_PREFIX="observability-operator"
  echo "Uninstalling Upstream Observability Operator (version: ${CSV_VERSION})..."
else
  SUB_NAME="cluster-observability-operator"
  CSV_PREFIX="cluster-observability-operator"
  echo "Uninstalling Cluster Observability Operator (downstream, version: ${CSV_VERSION})..."
fi

# Delete all instances of CRDs
for crd in $(oc get crd | grep 'monitoring.rhobs' | awk '{print $1}'); do
  echo "Deleting instances of $crd"
  oc delete $crd --all
done

# Delete all instances of CRDs
for crd in $(oc get crd | grep 'observability.openshift.io' | awk '{print $1}'); do
  echo "Deleting instances of $crd"
  oc delete $crd --all
done

echo ""
echo "Checking for remaining CRD instances..."

# Check for remaining monitoring.rhobs CRD instances
MONITORING_INSTANCES=0
for crd in $(oc get crd 2>/dev/null | grep 'monitoring.rhobs' | awk '{print $1}'); do
  RESOURCE_NAME=$(echo $crd | sed 's/.monitoring.rhobs//')
  COUNT=$(oc get $crd -A --no-headers 2>/dev/null | wc -l | xargs)
  if [ "$COUNT" -gt 0 ]; then
    echo "✗ Warning: $COUNT instance(s) of $crd still exist"
    oc get $crd -A 2>/dev/null
    MONITORING_INSTANCES=$((MONITORING_INSTANCES + COUNT))
  fi
done

# Check for remaining observability.openshift.io CRD instances
OBSERVABILITY_INSTANCES=0
for crd in $(oc get crd 2>/dev/null | grep 'observability.openshift.io' | awk '{print $1}'); do
  RESOURCE_NAME=$(echo $crd | sed 's/.observability.openshift.io//')
  COUNT=$(oc get $crd -A --no-headers 2>/dev/null | wc -l | xargs)
  if [ "$COUNT" -gt 0 ]; then
    echo "✗ Warning: $COUNT instance(s) of $crd still exist"
    oc get $crd -A 2>/dev/null
    OBSERVABILITY_INSTANCES=$((OBSERVABILITY_INSTANCES + COUNT))
  fi
done

if [ "$MONITORING_INSTANCES" -eq 0 ] && [ "$OBSERVABILITY_INSTANCES" -eq 0 ]; then
  echo "✓ No CRD instances remaining"
else
  echo "✗ Warning: $((MONITORING_INSTANCES + OBSERVABILITY_INSTANCES)) CRD instance(s) still exist"
  echo "  Please delete these instances manually before CRDs can be removed"
fi

# Delete subscription
oc -n "$NAMESPACE" delete sub "$SUB_NAME" 2>/dev/null || true

# Delete CSV with specified version and common fallbacks
echo "Deleting CSV ${CSV_PREFIX}.v${CSV_VERSION}..."
oc -n "$NAMESPACE" delete csv "${CSV_PREFIX}.v${CSV_VERSION}" 2>/dev/null || true

# Delete CRDs only if no instances remain
if [ "$MONITORING_INSTANCES" -eq 0 ] && [ "$OBSERVABILITY_INSTANCES" -eq 0 ]; then
  echo ""
  echo "Deleting CRDs..."
  oc delete crds $(oc api-resources --api-group=monitoring.rhobs -o name) 2>/dev/null || true
  oc delete crds $(oc api-resources --api-group=observability.openshift.io -o name) 2>/dev/null || true
else
  echo ""
  echo "Skipping CRD deletion due to existing instances"
fi

echo ""
echo "Checking for remaining resources in namespace '$NAMESPACE'..."

# Check for remaining pods
PODS=$(oc get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [ "$PODS" -eq 0 ]; then
  echo "✓ No pods remaining"
else
  echo "✗ Warning: $PODS pod(s) still present:"
  oc get pods -n "$NAMESPACE"
fi

# Check for remaining deployments
DEPLOYS=$(oc get deployment -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [ "$DEPLOYS" -eq 0 ]; then
  echo "✓ No deployments remaining"
else
  echo "✗ Warning: $DEPLOYS deployment(s) still present:"
  oc get deployment -n "$NAMESPACE"
fi

echo ""
echo "Uninstall complete!"
