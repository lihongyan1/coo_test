ssh -i ~/.ssh/openshift-qe.pem cloud-user@10.0.98.224

oc  get csv cluster-observability-operator.v1.2.2 -ojson | jq -r '.spec.relatedImages' | grep image | awk -F/ '{print $3}' |tr -d , | sed 's/"$//' | sort > csv.images

oc get component -ojson | jq -r '.items[] | select(.spec.application=="cluster-observability-operator-1-2" and .metadata.ownerReferences[0].name=="cluster-observability-operator-1-2")'| grep -E 'lastPromotedImage' | sort | awk -F/ '{print $5}' | sed 's/"$//' | sort >  /Users/hongyli/Documents/workdir/coo/konflux.images

oc describe snapshot cluster-observability-operator-1-2-4xhfb | grep 'Container Image:' | sort | awk -F/ '{print $5}' | sort > /Users/hongyli/Documents/workdir/coo/konflux.images

operator-sdk run bundle -n coo  --security-context-config restricted --timeout 5m quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle@sha256:e717712478e801794ea5eb191c26a1df5db23da603399bdb64a3b805efdc8b56

go test -v ./test/e2e/...  --retain=true --operatorInstallNS=openshift-cluster-observability-operator --run=TestMonitoringStackController/Prometheus_stacks_can_scrape_themselves_and_web_UI_works
 
oc get component -ojson | jq -r '.items[] | select(.spec.application|test("^coo-fbc"))' | grep lastPromotedImage | awk -F\" '{print $4}'
oc get component -ojson | jq -r '.items[] | select(.spec.application|test("^coo-fbc"))' | jq -r '.metadata.name, .status.lastBuiltCommit'
oc get component -ojson | jq -r '.items[] | select(.spec.application|test("^coo-fbc"))' | jq -r '.status.lastPromotedImage'>fbc-images
scp -i ~/.ssh/openshift-qe.pem ./fbc-images cloud-user@10.0.98.224:~/coo/coo_test/fbc-images

for release in $(oc get release --sort-by=.metadata.creationTimestamp | grep -i succeed | awk '{print $1}' | grep coo-fbc); do echo $release; oc describe release $release|grep -i index_image_resolved |awk '{print $2}'; done

oc get deployment -n openshift-cluster-observability-operator -o yaml | grep -o "registry.redhat.io/cluster-observability-operator/.*" | sort | uniq |sed 's/registry.redhat.io/registry.stage.redhat.io/' | awk -F/ '{print $3}' > deployment.image

for pod in $(oc get pod --no-headers | awk '{print $1}'); do echo $pod; oc logs $pod |tail -n 20 ;done
