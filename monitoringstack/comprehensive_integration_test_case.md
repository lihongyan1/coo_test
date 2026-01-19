# Comprehensive Integration Test Case
## PRs #941-#950: Full Feature Stack Testing

**Test ID:** INTEGRATION-001
**Test Type:** End-to-End Integration
**Priority:** P0 - Critical
**Estimated Duration:** 45 minutes
**PRs Covered:** #941, #942, #943, #944, #945, #946, #950

---

## Test Objective

Validate all features from PRs #941-#950 working together in a single, production-like MonitoringStack deployment that exercises:
- Prometheus Operator v0.87.0 with scheme configuration (PR #950)
- Alertmanager replicas configuration (PR #941)
- Size-based retention (PR #946)
- OTLP receiver configuration (PR #943)
- Null selector support with unmanaged config (PR #944)
- Automatic secret reconciliation (PR #945)
- Perses owner references (PR #942)

---

## Prerequisites

```bash
export KUBECONFIG=/path/to/kubeconfig
export TEST_NAMESPACE=integration-test-all
export MONITORING_NAMESPACE=openshift-cluster-observability-operator

# Create test namespace
oc create namespace $TEST_NAMESPACE
```

---

## Test Scenario: Production-Like Monitoring Stack

### Phase 1: Deploy Complete MonitoringStack (15 min)

#### Step 1.1: Create Supporting Resources

**Create TLS Certificates:**
```bash
# Generate self-signed certificates for testing
openssl req -x509 -newkey rsa:2048 -nodes -keyout tls.key -out tls.crt \
  -days 365 -subj "/CN=monitoring.example.com"

openssl req -x509 -newkey rsa:2048 -nodes -keyout tls-new.key -out tls-new.crt \
  -days 365 -subj "/CN=monitoring-updated.example.com"
```

**Create Secrets:**
```bash
# TLS secret for ServiceMonitor
oc create secret tls monitoring-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n $TEST_NAMESPACE

# Remote write bearer token
oc create secret generic remote-write-token \
  --from-literal=token=initial-remote-write-token-12345 \
  -n $TEST_NAMESPACE

# Basic auth for ServiceMonitor
oc create secret generic app-basic-auth \
  --from-literal=username=monitoring-user \
  --from-literal=password=initial-password-123 \
  -n $TEST_NAMESPACE
```

**Expected Results:**
- ✅ 3 secrets created successfully
- ✅ No errors during secret creation

---

#### Step 1.2: Deploy MonitoringStack with All Features

**Apply MonitoringStack:**
```yaml
apiVersion: monitoring.rhobs/v1alpha1
kind: MonitoringStack
metadata:
  name: comprehensive-stack
  namespace: integration-test-all
  labels:
    test-suite: pr-941-950
spec:
  # PR #946: Size-based retention
  retention: 7d
  retentionSize: 5GB

  logLevel: debug

  resourceSelector:
    matchLabels:
      monitoring: comprehensive

  # PR #941: Alertmanager replicas
  alertmanagerConfig:
    replicas: 2  # Should create PDB
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
      limits:
        memory: 512Mi
        cpu: 500m

  prometheusConfig:
    # PR #950: Scheme configuration (tested via ServiceMonitors)
    replicas: 2

    # PR #943: OTLP receiver
    enableOtlpHttpReceiver: true

    # PR #945: Remote write with secret (will test secret updates)
    remoteWrite:
    - url: http://mock-remote-prometheus:9090/api/v1/write
      bearerTokenSecret:
        name: remote-write-token
        key: token

    # PR #946: Retention with PVC
    persistentVolumeClaim:
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 10Gi

    resources:
      requests:
        memory: 512Mi
        cpu: 200m
      limits:
        memory: 2Gi
        cpu: 1000m
```

**Apply:**
```bash
oc apply -f comprehensive-monitoringstack.yaml
```

**Wait for Deployment:**
```bash
# Wait for Prometheus pods
oc wait --for=condition=Ready pod -l app.kubernetes.io/name=prometheus \
  -n $TEST_NAMESPACE --timeout=300s

# Wait for Alertmanager pods
oc wait --for=condition=Ready pod -l app.kubernetes.io/name=alertmanager \
  -n $TEST_NAMESPACE --timeout=300s
```

**Validation - Phase 1.2:**
```bash
# 1. Verify Prometheus Operator version (PR #950)
echo "=== Checking Prometheus Operator Version ==="
oc get pod -n $MONITORING_NAMESPACE -l app.kubernetes.io/name=prometheus-operator \
  -o jsonpath='{.items[0].metadata.labels.app\.kubernetes\.io/version}'
# Expected: 0.87.0-rhobs1

# 2. Verify Prometheus replicas
echo "=== Checking Prometheus Replicas ==="
oc get pods -n $TEST_NAMESPACE -l app.kubernetes.io/name=prometheus
# Expected: 2 pods running

# 3. Verify Alertmanager replicas and PDB (PR #941)
echo "=== Checking Alertmanager Configuration ==="
oc get pods -n $TEST_NAMESPACE -l app.kubernetes.io/name=alertmanager
oc get pdb -n $TEST_NAMESPACE
# Expected: 2 Alertmanager pods + PDB exists

# 4. Verify retention configuration (PR #946)
echo "=== Checking Retention Configuration ==="
oc get statefulset -n $TEST_NAMESPACE -o yaml | grep -E "retention\.(time|size)"
# Expected:
# --storage.tsdb.retention.time=7d
# --storage.tsdb.retention.size=5GB

# 5. Verify OTLP receiver (PR #943)
echo "=== Checking OTLP Receiver ==="
oc get statefulset -n $TEST_NAMESPACE -o yaml | grep "otlp"
# Expected: --web.enable-otlp-receiver (for Prometheus 3.x)

# 6. Verify operator flags (PR #944, #945)
echo "=== Checking Operator Flags ==="
oc get deployment obo-prometheus-operator -n $MONITORING_NAMESPACE -o yaml | \
  grep -E "disable-unmanaged|watch-referenced"
# Expected:
# --disable-unmanaged-prometheus-configuration=true
# --watch-referenced-objects-in-all-namespaces=true

# 7. Check operator logs for errors
echo "=== Checking Operator Logs ==="
oc logs deployment/observability-operator -n $MONITORING_NAMESPACE --tail=50 | \
  grep -iE "error|fail" | grep -v "Failed to reconcile.*OpenTelemetryCollector"
# Expected: No critical errors (OpenTelemetryCollector errors are expected if not installed)
```

**Expected Results:**
- ✅ MonitoringStack created successfully
- ✅ 2 Prometheus pods running and ready
- ✅ 2 Alertmanager pods running and ready
- ✅ PDB created for Alertmanager
- ✅ Retention time and size configured
- ✅ OTLP receiver enabled
- ✅ Operator flags correctly set
- ✅ Remote write secret referenced

---

### Phase 2: Deploy Sample Applications (5 min)

#### Step 2.1: Deploy Applications with Different Schemes

**Application 1: HTTP Scheme (Uppercase)**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-http-uppercase
  namespace: integration-test-all
  labels:
    monitoring: comprehensive
    app: http-uppercase
spec:
  ports:
  - name: metrics
    port: 8080
    targetPort: 8080
  selector:
    app: http-uppercase
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-http-uppercase
  namespace: integration-test-all
spec:
  replicas: 2
  selector:
    matchLabels:
      app: http-uppercase
  template:
    metadata:
      labels:
        app: http-uppercase
        monitoring: comprehensive
    spec:
      containers:
      - name: app
        image: quay.io/brancz/prometheus-example-app:v0.3.0
        ports:
        - containerPort: 8080
          name: metrics
        resources:
          requests:
            memory: 64Mi
            cpu: 50m
          limits:
            memory: 128Mi
            cpu: 100m
```

**Application 2: http Scheme (Lowercase)**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-http-lowercase
  namespace: integration-test-all
  labels:
    monitoring: comprehensive
    app: http-lowercase
spec:
  ports:
  - name: metrics
    port: 8080
    targetPort: 8080
  selector:
    app: http-lowercase
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-http-lowercase
  namespace: integration-test-all
spec:
  replicas: 2
  selector:
    matchLabels:
      app: http-lowercase
  template:
    metadata:
      labels:
        app: http-lowercase
        monitoring: comprehensive
    spec:
      containers:
      - name: app
        image: quay.io/brancz/prometheus-example-app:v0.3.0
        ports:
        - containerPort: 8080
          name: metrics
```

**Apply:**
```bash
oc apply -f app-http-uppercase.yaml
oc apply -f app-http-lowercase.yaml

# Wait for deployments
oc wait --for=condition=Available deployment/app-http-uppercase -n $TEST_NAMESPACE --timeout=120s
oc wait --for=condition=Available deployment/app-http-lowercase -n $TEST_NAMESPACE --timeout=120s
```

**Expected Results:**
- ✅ 2 deployments created
- ✅ 4 application pods running (2 per deployment)

---

#### Step 2.2: Create ServiceMonitors with Different Schemes (PR #950)

**ServiceMonitor 1: Uppercase HTTP with TLS Secret**
```yaml
apiVersion: monitoring.rhobs/v1
kind: ServiceMonitor
metadata:
  name: http-uppercase-monitor
  namespace: integration-test-all
  labels:
    monitoring: comprehensive
spec:
  selector:
    matchLabels:
      app: http-uppercase
  endpoints:
  - port: metrics
    scheme: HTTP  # PR #950: Uppercase scheme
    interval: 15s
    path: /metrics
    # PR #945: TLS config with secret (will test secret updates)
    tlsConfig:
      insecureSkipVerify: true
      ca:
        secret:
          name: monitoring-tls
          key: tls.crt
```

**ServiceMonitor 2: Lowercase http with Basic Auth**
```yaml
apiVersion: monitoring.rhobs/v1
kind: ServiceMonitor
metadata:
  name: http-lowercase-monitor
  namespace: integration-test-all
  labels:
    monitoring: comprehensive
spec:
  selector:
    matchLabels:
      app: http-lowercase
  endpoints:
  - port: metrics
    scheme: http  # PR #950: Lowercase scheme
    interval: 15s
    path: /metrics
    # PR #945: Basic auth with secret (will test secret updates)
    basicAuth:
      username:
        name: app-basic-auth
        key: username
      password:
        name: app-basic-auth
        key: password
```

**PodMonitor with HTTP Scheme**
```yaml
apiVersion: monitoring.rhobs/v1
kind: PodMonitor
metadata:
  name: pod-http-monitor
  namespace: integration-test-all
  labels:
    monitoring: comprehensive
spec:
  selector:
    matchLabels:
      monitoring: comprehensive
  podMetricsEndpoints:
  - port: metrics
    scheme: HTTP  # PR #950: PodMonitor with uppercase
    interval: 30s
```

**Apply:**
```bash
oc apply -f servicemonitor-uppercase.yaml
oc apply -f servicemonitor-lowercase.yaml
oc apply -f podmonitor-http.yaml
```

**Validation - Phase 2.2:**
```bash
# 1. Verify ServiceMonitors created
echo "=== Checking ServiceMonitors ==="
oc get servicemonitor.monitoring.rhobs -n $TEST_NAMESPACE

# 2. Check scheme values
echo "=== Verifying Scheme Values ==="
oc get servicemonitor.monitoring.rhobs http-uppercase-monitor -n $TEST_NAMESPACE \
  -o jsonpath='{.spec.endpoints[0].scheme}'
echo ""
oc get servicemonitor.monitoring.rhobs http-lowercase-monitor -n $TEST_NAMESPACE \
  -o jsonpath='{.spec.endpoints[0].scheme}'
echo ""

# 3. Check PodMonitor
oc get podmonitor.monitoring.rhobs pod-http-monitor -n $TEST_NAMESPACE \
  -o jsonpath='{.spec.podMetricsEndpoints[0].scheme}'
echo ""

# 4. Verify no scheme-related errors in operator logs
oc logs deployment/obo-prometheus-operator -n $MONITORING_NAMESPACE --tail=100 | \
  grep -i "scheme" | grep -iE "error|fail" || echo "No scheme errors - PASS"
```

**Expected Results:**
- ✅ Both ServiceMonitors created (uppercase and lowercase schemes)
- ✅ PodMonitor created with HTTP scheme
- ✅ No scheme validation errors
- ✅ Prometheus configuration updated

---

#### Step 2.3: Create PrometheusRules

**PrometheusRules:**
```yaml
apiVersion: monitoring.rhobs/v1
kind: PrometheusRule
metadata:
  name: comprehensive-alerts
  namespace: integration-test-all
  labels:
    monitoring: comprehensive
spec:
  groups:
  - name: application-alerts
    interval: 30s
    rules:
    - alert: ApplicationDown
      expr: up{job=~".*http-(uppercase|lowercase).*"} == 0
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Application is down"
        description: "Application {{ $labels.job }} has been down for more than 2 minutes"

    - alert: HighRequestRate
      expr: rate(http_requests_total[5m]) > 100
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High request rate detected"

  - name: prometheus-alerts
    interval: 30s
    rules:
    - alert: PrometheusStorageNearFull
      expr: |
        (prometheus_tsdb_storage_blocks_bytes /
         prometheus_tsdb_retention_limit_bytes) > 0.8
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Prometheus storage is {{ $value | humanizePercentage }} full"
```

**Apply:**
```bash
oc apply -f prometheusrules.yaml
```

**Expected Results:**
- ✅ PrometheusRules created
- ✅ Rules loaded in Prometheus

---

### Phase 3: Test Secret Reconciliation (PR #945) (10 min)

#### Step 3.1: Update TLS Secret

```bash
echo "=== Testing TLS Secret Update (PR #945) ==="

# Record start time
START_TIME=$(date +%s)

# Update TLS secret
oc create secret tls monitoring-tls \
  --cert=tls-new.crt \
  --key=tls-new.key \
  -n $TEST_NAMESPACE \
  --dry-run=client -o yaml | oc apply -f -

# Monitor operator logs for reconciliation
echo "Monitoring operator logs for reconciliation..."
timeout 60s oc logs deployment/obo-prometheus-operator -n $MONITORING_NAMESPACE \
  --tail=100 -f | grep -i "monitoring-tls\|reconcil" &

# Wait for reconciliation
sleep 30

# Record end time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "TLS secret updated. Reconciliation time: ${DURATION}s"
```

**Expected Results:**
- ✅ Secret update detected within 30 seconds
- ✅ Operator logs show reconciliation activity
- ✅ Prometheus configuration updated (pod may reload)

---

#### Step 3.2: Update Basic Auth Secret

```bash
echo "=== Testing Basic Auth Secret Update (PR #945) ==="

# Update basic auth secret
oc create secret generic app-basic-auth \
  --from-literal=username=monitoring-user \
  --from-literal=password=updated-password-456 \
  -n $TEST_NAMESPACE \
  --dry-run=client -o yaml | oc apply -f -

# Wait and verify
sleep 30

# Check operator logs
oc logs deployment/obo-prometheus-operator -n $MONITORING_NAMESPACE --tail=100 | \
  grep -i "app-basic-auth" || echo "Secret reconciliation in progress"
```

**Expected Results:**
- ✅ Basic auth secret update detected
- ✅ ServiceMonitor reconciled
- ✅ New credentials applied to scrape config

---

#### Step 3.3: Update Remote Write Secret

```bash
echo "=== Testing Remote Write Secret Update (PR #945) ==="

# Update remote write token
oc create secret generic remote-write-token \
  --from-literal=token=updated-remote-write-token-67890 \
  -n $TEST_NAMESPACE \
  --dry-run=client -o yaml | oc apply -f -

# Wait and verify
sleep 30

# Verify Prometheus configuration updated
PROM_POD=$(oc get pod -n $TEST_NAMESPACE -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')
oc exec $PROM_POD -n $TEST_NAMESPACE -c prometheus -- \
  cat /etc/prometheus/config_out/prometheus.env.yaml | grep -A 10 "remote_write"
```

**Expected Results:**
- ✅ Remote write secret update detected
- ✅ Prometheus remote write config updated
- ✅ New token in Prometheus configuration

---

### Phase 4: Test Alertmanager Scaling (PR #941) (5 min)

#### Step 4.1: Scale Alertmanager to 1 (Remove PDB)

```bash
echo "=== Testing Alertmanager Scale Down (PR #941) ==="

# Scale to 1 replica
oc patch monitoringstack comprehensive-stack -n $TEST_NAMESPACE --type=merge \
  -p '{"spec":{"alertmanagerConfig":{"replicas":1}}}'

# Wait for reconciliation
sleep 20

# Verify
echo "Checking Alertmanager pods..."
oc get pods -n $TEST_NAMESPACE -l app.kubernetes.io/name=alertmanager

echo "Checking PDB..."
oc get pdb -n $TEST_NAMESPACE | grep alertmanager || echo "PDB removed - PASS"
```

**Expected Results:**
- ✅ Alertmanager scaled to 1 replica
- ✅ PDB removed (since replicas == 1)
- ✅ Alertmanager continues to function

---

#### Step 4.2: Scale Alertmanager to 3 (Create PDB)

```bash
echo "=== Testing Alertmanager Scale Up (PR #941) ==="

# Scale to 3 replicas
oc patch monitoringstack comprehensive-stack -n $TEST_NAMESPACE --type=merge \
  -p '{"spec":{"alertmanagerConfig":{"replicas":3}}}'

# Wait for reconciliation
sleep 30

# Verify
echo "Checking Alertmanager pods..."
oc get pods -n $TEST_NAMESPACE -l app.kubernetes.io/name=alertmanager

echo "Checking PDB..."
oc get pdb -n $TEST_NAMESPACE
```

**Expected Results:**
- ✅ Alertmanager scaled to 3 replicas
- ✅ PDB created (since replicas > 1)
- ✅ All 3 Alertmanager pods running
- ✅ PDB has appropriate minAvailable setting

---

### Phase 5: Test Retention Size Update (PR #946) (5 min)

#### Step 5.1: Update RetentionSize

```bash
echo "=== Testing RetentionSize Update (PR #946) ==="

# Update retention size from 5GB to 10GB
oc patch monitoringstack comprehensive-stack -n $TEST_NAMESPACE --type=merge \
  -p '{"spec":{"retentionSize":"10GB"}}'

# Wait for pod restart
sleep 30

# Verify new retention size
oc get statefulset -n $TEST_NAMESPACE -o yaml | grep "retention.size"
# Expected: --storage.tsdb.retention.size=10GB
```

**Expected Results:**
- ✅ RetentionSize updated to 10GB
- ✅ Prometheus StatefulSet updated
- ✅ Prometheus pods restarted with new configuration
- ✅ New retention size in effect

---

### Phase 6: Test Null Selector (PR #944) (5 min)

#### Step 6.1: Create MonitoringStack with Null Selector

```bash
echo "=== Testing Null Resource Selector (PR #944) ==="

# Create MonitoringStack with null selector
cat <<EOF | oc apply -f -
apiVersion: monitoring.rhobs/v1alpha1
kind: MonitoringStack
metadata:
  name: null-selector-stack
  namespace: $TEST_NAMESPACE
spec:
  resourceSelector: null
  retention: 1h
  logLevel: debug
  prometheusConfig:
    replicas: 1
EOF

# Wait for deployment
sleep 30

# Check Prometheus pod readiness
oc wait --for=condition=Ready pod -l app.kubernetes.io/name=prometheus,prometheus=null-selector-stack \
  -n $TEST_NAMESPACE --timeout=300s

# Get Prometheus pod
NULL_PROM_POD=$(oc get pod -n $TEST_NAMESPACE -l prometheus=null-selector-stack -o jsonpath='{.items[0].metadata.name}')

# Check Thanos sidecar (should start without errors)
echo "Checking Thanos sidecar logs..."
oc logs $NULL_PROM_POD -n $TEST_NAMESPACE -c thanos-sidecar --tail=50 | \
  grep -i "external labels\|error" || echo "Thanos sidecar healthy - PASS"

# Verify empty Prometheus configuration
echo "Checking Prometheus configuration..."
oc exec $NULL_PROM_POD -n $TEST_NAMESPACE -c prometheus -- \
  cat /etc/prometheus/config_out/prometheus.env.yaml | grep "scrape_configs" -A 5
```

**Expected Results:**
- ✅ MonitoringStack with null selector created
- ✅ Prometheus pod starts successfully
- ✅ Thanos sidecar starts without external label errors
- ✅ Prometheus configuration is empty (no scrape configs)
- ✅ Can be used for remote-write/OTLP-only deployments

---

### Phase 7: Test Perses Owner References (PR #942) (Optional)

*Skip if Perses operator is not installed*

```bash
echo "=== Testing Perses Owner References (PR #942) ==="

# Create UIPlugin
cat <<EOF | oc apply -f -
apiVersion: observability.openshift.io/v1alpha1
kind: UIPlugin
metadata:
  name: test-perses-plugin
  namespace: $TEST_NAMESPACE
spec:
  type: Perses
EOF

# Wait for Perses CR creation
sleep 10

# Check owner references
oc get perses -n $TEST_NAMESPACE -o yaml | grep -A 10 "ownerReferences"

# Delete UIPlugin and verify Perses is also deleted
oc delete uiplugin test-perses-plugin -n $TEST_NAMESPACE

# Watch for Perses deletion (should happen automatically)
sleep 10
oc get perses -n $TEST_NAMESPACE || echo "Perses automatically deleted - PASS"
```

**Expected Results:**
- ✅ Perses CR created with owner references
- ✅ Owner references point to UIPlugin
- ✅ Deleting UIPlugin automatically deletes Perses
- ✅ No orphaned resources

---

### Phase 8: End-to-End Validation (5 min)

#### Step 8.1: Verify Metrics Scraping

```bash
echo "=== End-to-End Metrics Validation ==="

# Port-forward to Prometheus
PROM_POD=$(oc get pod -n $TEST_NAMESPACE -l app.kubernetes.io/name=prometheus,prometheus=comprehensive-stack \
  -o jsonpath='{.items[0].metadata.name}')

oc port-forward $PROM_POD -n $TEST_NAMESPACE 9090:9090 &
PF_PID=$!

# Wait for port-forward
sleep 5

# Query metrics
echo "Querying Prometheus for application metrics..."
curl -s 'http://localhost:9090/api/v1/query?query=up{job=~".*http.*"}' | jq -r '.data.result[] | "\(.metric.job): \(.value[1])"'

# Query for scrape targets
echo "Checking configured targets..."
curl -s 'http://localhost:9090/api/v1/targets' | jq -r '.data.activeTargets[] | "\(.scrapeUrl) - \(.health)"'

# Check alerts
echo "Checking alert rules..."
curl -s 'http://localhost:9090/api/v1/rules' | jq -r '.data.groups[].rules[] | select(.type=="alerting") | .name'

# Kill port-forward
kill $PF_PID
```

**Expected Results:**
- ✅ Both applications (uppercase and lowercase) are being scraped
- ✅ Metrics show "up" status
- ✅ Alert rules are loaded
- ✅ No scrape errors

---

#### Step 8.2: Overall Health Check

```bash
echo "=== Overall System Health Check ==="

# Check all pods
echo "Prometheus pods:"
oc get pods -n $TEST_NAMESPACE -l app.kubernetes.io/name=prometheus

echo "Alertmanager pods:"
oc get pods -n $TEST_NAMESPACE -l app.kubernetes.io/name=alertmanager

echo "Application pods:"
oc get pods -n $TEST_NAMESPACE -l monitoring=comprehensive

# Check all monitoring resources
echo "Monitoring resources:"
oc get monitoringstack,servicemonitor,podmonitor,prometheusrule -n $TEST_NAMESPACE

# Check operator health
echo "Operator health:"
oc get pods -n $MONITORING_NAMESPACE -l app.kubernetes.io/name=prometheus-operator
oc logs deployment/observability-operator -n $MONITORING_NAMESPACE --tail=20

# Check for any errors
echo "Checking for errors..."
oc get events -n $TEST_NAMESPACE --field-selector type=Warning --sort-by='.lastTimestamp' | tail -10
```

---

## Test Results Summary

### ✅ Pass Criteria Checklist

**PR #950 - Prometheus Operator v0.87.0 & Scheme:**
- [ ] CRDs at version 0.87.0-rhobs1
- [ ] Operator pod running v0.87.0-rhobs1
- [ ] ServiceMonitor with uppercase "HTTP" scheme accepted
- [ ] ServiceMonitor with lowercase "http" scheme accepted
- [ ] PodMonitor with "HTTP" scheme accepted
- [ ] No scheme-related errors in operator logs

**PR #941 - Alertmanager Replicas:**
- [ ] Default 2 replicas deployed with PDB
- [ ] Scaling to 1 replica removes PDB
- [ ] Scaling to 3 replicas creates PDB
- [ ] Alertmanager functions at all replica counts

**PR #946 - RetentionSize:**
- [ ] RetentionSize "5GB" configured initially
- [ ] `--storage.tsdb.retention.size=5GB` in Prometheus args
- [ ] Update to "10GB" successfully applied
- [ ] Both time and size retention working together

**PR #943 - OTLP Receiver:**
- [ ] `enableOtlpHttpReceiver: true` configured
- [ ] `--web.enable-otlp-receiver` flag in Prometheus args (modern version)
- [ ] No legacy flag present
- [ ] Prometheus starts successfully with OTLP enabled

**PR #944 - Null Selector:**
- [ ] MonitoringStack with null selector deploys
- [ ] Prometheus pod starts successfully
- [ ] Thanos sidecar starts without errors
- [ ] Empty configuration (no scrape configs)
- [ ] `--disable-unmanaged-prometheus-configuration=true` flag set

**PR #945 - Secret Watching:**
- [ ] TLS secret update triggers reconciliation
- [ ] Basic auth secret update triggers reconciliation
- [ ] Remote write secret update triggers reconciliation
- [ ] Reconciliation completes within 60 seconds
- [ ] `--watch-referenced-objects-in-all-namespaces=true` flag set

**PR #942 - Perses Owner References:**
- [ ] Perses CR created with owner references
- [ ] Owner references point to UIPlugin correctly
- [ ] Deleting UIPlugin deletes Perses automatically
- [ ] No orphaned Perses resources

**Integration:**
- [ ] All features work together without conflicts
- [ ] No operator crashes or errors
- [ ] Metrics successfully scraped from applications
- [ ] PrometheusRules loaded correctly
- [ ] System remains stable throughout test

---

## Cleanup

```bash
echo "=== Cleaning Up Test Resources ==="

# Delete MonitoringStacks
oc delete monitoringstack comprehensive-stack null-selector-stack -n $TEST_NAMESPACE

# Delete entire namespace
oc delete namespace $TEST_NAMESPACE

# Verify cleanup
oc get namespace $TEST_NAMESPACE 2>&1 | grep -q "NotFound" && echo "Cleanup complete!"
```

---

## Troubleshooting

### Issue: Prometheus Pod Not Ready
```bash
# Check pod events
oc describe pod <prometheus-pod> -n $TEST_NAMESPACE

# Check logs
oc logs <prometheus-pod> -n $TEST_NAMESPACE -c prometheus --tail=100
oc logs <prometheus-pod> -n $TEST_NAMESPACE -c config-reloader --tail=100
oc logs <prometheus-pod> -n $TEST_NAMESPACE -c thanos-sidecar --tail=100
```

### Issue: Secret Updates Not Triggering Reconciliation
```bash
# Verify watch flag
oc get deployment obo-prometheus-operator -n $MONITORING_NAMESPACE -o yaml | \
  grep "watch-referenced-objects-in-all-namespaces"

# Check RBAC
oc auth can-i watch secrets --as=system:serviceaccount:$MONITORING_NAMESPACE:prometheus-operator

# Check operator logs
oc logs deployment/obo-prometheus-operator -n $MONITORING_NAMESPACE --tail=200 | \
  grep -i "watch\|secret\|reconcil"
```

### Issue: Scheme Validation Errors
```bash
# Check CRD version
oc get crd servicemonitors.monitoring.rhobs -o jsonpath='{.metadata.annotations.operator\.prometheus\.io/version}'

# Check operator logs for scheme errors
oc logs deployment/obo-prometheus-operator -n $MONITORING_NAMESPACE --tail=200 | \
  grep -i "scheme"
```

---

## Test Execution Time

| Phase | Activity | Duration |
|-------|----------|----------|
| 1 | Deploy MonitoringStack | 15 min |
| 2 | Deploy Applications & Monitors | 5 min |
| 3 | Test Secret Reconciliation | 10 min |
| 4 | Test Alertmanager Scaling | 5 min |
| 5 | Test Retention Size Update | 5 min |
| 6 | Test Null Selector | 5 min |
| 7 | Test Perses (Optional) | 3 min |
| 8 | End-to-End Validation | 5 min |
| **Total** | | **~45 min** |

---

## Success Metrics

### Critical Success Factors
1. **All 7 PRs features functional** in single deployment
2. **No operator errors or crashes** during entire test
3. **Automatic reconciliation working** for secret updates
4. **Metrics successfully scraped** from all applications
5. **All components remain stable** throughout test

### Performance Benchmarks
- Secret reconciliation: < 60 seconds
- Pod startup time: < 120 seconds
- Metrics scrape successful rate: > 99%
- Zero operator restarts during test

---

**END OF COMPREHENSIVE INTEGRATION TEST CASE**
