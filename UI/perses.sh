oc create ns perses-dev
oc apply -f https://raw.githubusercontent.com/etmurasaki/dotfiles/refs/heads/main/scripts/rbac/dashboards/openshift-cluster-sample-dashboard.yaml
oc apply -f https://raw.githubusercontent.com/etmurasaki/dotfiles/refs/heads/main/scripts/rbac/dashboards/perses-dashboard-sample.yaml
oc apply -f https://raw.githubusercontent.com/etmurasaki/dotfiles/refs/heads/main/scripts/rbac/dashboards/prometheus-overview-variables.yaml
oc apply -f https://raw.githubusercontent.com/etmurasaki/dotfiles/refs/heads/main/scripts/rbac/dashboards/thanos-compact-overview-1var.yaml
oc apply -f https://raw.githubusercontent.com/etmurasaki/dotfiles/refs/heads/main/scripts/rbac/dashboards/thanos-querier-datasource.yaml
