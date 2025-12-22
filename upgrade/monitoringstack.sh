cd /Users/hongyli/projects/rhobs/observability-operator
go test -v -failfast ./test/e2e/... --retain=true -run TestMonitoringStackController/Verify_multi-namespace_support
oc -n e2e-tests label monitoringstack multi-ns  mso=example
cd -
cat <<EOF|oc create -f -
apiVersion: monitoring.rhobs/v1alpha1
kind: ThanosQuerier
metadata:
  name: example-thanos
  namespace: e2e-tests
spec:
  selector:
    matchLabels:
      mso: example
---
EOF

oc -n e2e-tests get pod
oc -n e2e-tests exec deploy/thanos-querier-example-thanos -- curl -k 'http://thanos-querier-example-thanos.e2e-tests.svc:10902/api/v1/query?' --data-urlencode 'query=version' | jq

