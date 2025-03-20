oc -n coo get csv cluster-observability-operator.v1.1.0 -ojson | jq -r '.spec.relatedImages' | grep image | sort | awk -F/ '{print $3}' |tr -d , >csv.images

oc get component -ojson | jq -r '.items[] | select(.spec.application=="cluster-observability-operator-1-1" and .metadata.ownerReferences[0].name=="cluster-observability-operator-1-1")'| grep -E 'lastPromotedImage' | sort | awk -F/ '{print $5}' > > /Users/hongyli/Documents/workdir/coo/konflux.images

operator-sdk run bundle -n coo  --security-context-config restricted --timeout 5m quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:e717712478e801794ea5eb191c26a1df5db23da603399bdb64a3b805efdc8b56

go test -v ./test/e2e/...  --retain=true --operatorInstallNS=openshift-cluster-observability-operator --run=TestMonitoringStackController/Prometheus_stacks_can_scrape_themselves_and_web_UI_works
 
oc get component -ojson | jq -r '.items[] | select(.spec.application|test("^coo-fbc"))' | grep lastPromotedImage
