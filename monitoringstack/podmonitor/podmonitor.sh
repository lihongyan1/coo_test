oc create namespace ns1
oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: prometheus-example-app
  name: prometheus-example-app
  namespace: ns1
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: prometheus-example-app
  template:
    metadata:
      labels:
        app.kubernetes.io/name: prometheus-example-app
    spec:
      containers:
      - name: prometheus-example-app
        image: quay.io/openshifttest/prometheus-example-app@sha256:382dc349f82d730b834515e402b48a9c7e2965d0efbc42388bd254f424f6193e
        ports:
        - name: web
          containerPort: 8080
---
apiVersion: monitoring.rhobs/v1
kind: PodMonitor
metadata:
  labels:
    app.kubernetes.io/name: prometheus-example-app
  name: prometheus-example-app
  namespace: ns1
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: prometheus-example-app
  podMetricsEndpoints:
  - port: web
---
apiVersion: monitoring.rhobs/v1alpha1
kind: MonitoringStack
metadata:
  labels:
    mso: example
  name: podmonitor-test
  namespace: ns1
spec:
  alertmanagerConfig:
    disabled: false
  logLevel: info
  namespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: ns1
  prometheusConfig:
    replicas: 2
  resourceSelector:
    matchLabels:
      app.kubernetes.io/name: prometheus-example-app
  resources: {}
  retention: 120h
---
apiVersion: monitoring.rhobs/v1alpha1
kind: ThanosQuerier
metadata:
  name: example-thanos
  namespace: ns1
spec:
  selector:
    matchLabels:
      mso: example
EOF

echo "Waiting for prometheus-example-app deployment to be ready..."
oc wait -n ns1 --for=condition=Available deploy/prometheus-example-app --timeout=300s

echo "Waiting for thanos-querier deployment to be ready..."
oc wait -n ns1 --for=condition=Available deploy/thanos-querier-example-thanos --timeout=300s

echo "Waiting for thanos-querier pod to be running..."
oc wait -n ns1 --for=condition=Ready pod -l app.kubernetes.io/name=thanos-querier --timeout=300s

echo "Executing curl command on thanos-querier..."
oc -n ns1 exec deploy/thanos-querier-example-thanos -- curl -k 'http://thanos-querier-example-thanos.ns1.svc:10902/api/v1/query?' --data-urlencode 'query=prometheus_build_info' | jq
oc -n ns1 exec deploy/thanos-querier-example-thanos -- curl -k 'http://thanos-querier-example-thanos.ns1.svc:10902/api/v1/query?' --data-urlencode 'query=version' | jq


