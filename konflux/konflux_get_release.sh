for release in $(oc get release --sort-by=.metadata.creationTimestamp | awk '{print $1}' | grep coo-fbc | grep feb13); do echo $release;oc describe release $release|grep -i index_image_resolved; done
