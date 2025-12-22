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
