oc apply -f - <<EOF
apiVersion: observability.openshift.io/v1alpha1
kind: UIPlugin
metadata:
  name: monitoring
spec:
  monitoring:
    alertmanager:
      url: 'https://alertmanager-main.openshift-monitoring.svc:9094'
    thanosQuerier:
      url: 'https://thanos-querier.openshift-monitoring.svc:9091'
  type: Monitoring
EOF

