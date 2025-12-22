for crd in $(oc get crd | grep rhobs | awk '{print $1}' );do echo $crd;oc delete $crd --all -n ns1 ; done
oc delete uiplugins.observability.openshift.io --all
oc -n openshift-cluster-observability-operator delete sub cluster-observability-operator
oc -n openshift-cluster-observability-operator delete csv cluster-observability-operator.v1.3.0
oc delete crds $(oc api-resources --api-group=monitoring.rhobs -o name)
oc delete crds $(oc api-resources --api-group=observability.openshift.io -o name)
