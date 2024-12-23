ssh -i ~/.ssh/openshift-qe.pem cloud-user@10.0.98.224

operator-sdk run bundle -n coo  --security-context-config restricted --timeout 5m  quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator-bundle@sha256:9f5e7272d23844ef985bcacb36bc68d3442a752aeb1d8edff78f20e46ff4f31a

go test -v ./test/e2e/... -run TestPrometheusOperatorForNonOwnedResources/Operator_should_not_reconcile_resources_which_it_does_not_own/Thanos_Ruler_never_exists -args -operatorInstallNS=openshift-cluster-observability-operator
