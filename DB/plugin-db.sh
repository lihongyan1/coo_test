#set -eux
#From ObO user doc
oc apply -f - <<EOF
apiVersion: observability.openshift.io/v1alpha1
kind: UIPlugin
metadata:
  name: dashboards
spec:
  type: Dashboards
EOF
#https://github.com/openshift/console-dashboards-plugin/blob/main/docs/prometheus-datasource-example.yaml
oc apply -f - <<EOF 
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-prometheus-proxy
  namespace: openshift-config-managed
  labels:
    console.openshift.io/dashboard-datasource: "true"
data:
  "dashboard-datasource.yaml": |-
    kind: "Datasource"
    metadata:
      name: "cluster-prometheus-proxy"
      project: "openshift-config-managed"
    spec:
      plugin:
        kind: "prometheus"
        spec:
          direct_url: 'https://thanos-querier.openshift-monitoring.svc.cluster.local:9091'
EOF 
#oc -n openshift-config-managed get cm dashboard-prometheus -o jsonpath='{.data.prometheus\.json}' > prometheus.json
#oc -n openshift-config-managed create cm dashboard-example --from-file=prometheus.json --dry-run=client -o yaml  > example-DB.yaml
#oc apply -f ./example-DB.yaml
oc create configmap test-db-plugin-admin --from-file=/Users/hongyli/Documents/workdir/coo/UI/prometheus.json -n openshift-config-managed 
oc -n openshift-config-managed label cm test-db-plugin-admin console.openshift.io/dashboard=true
# oc -n openshift-config-managed get cm grafana-dashboard-k8s-resources-pod -o jsonpath='{.data.k8s-resources-pod\.json}' > k8s-resources-pod.json
# sed -i '' 's#Kubernetes /#DB Plugin Kubernetes /#g' k8s-resources-pod.json
# sed -i '' 's#$datasource#cluster-prometheus-proxy#g' k8s-resources-pod.json
#oc create configmap test-db-plugin-dev --from-file=k8s-resources-pod.json -n openshift-config-managed
#oc -n openshift-config-managed label cm test-db-plugin-dev console.openshift.io/odc-dashboard=true
#oc edit consoles.operator.openshift.io  cluster
