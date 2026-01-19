---
allowed-tools: Bash(curl:*), Bash(export:*), Bash(oc:*), Bash(ls:*)
argument-hint: [jenkins-job-id]
description: Download kubeconfig from Jenkins and install COO in production mode
---

## Task

Download kubeconfig file from Jenkins for job ID $1 and install COO in production mode.

## Context

- Jenkins job ID: $1
- Jenkins URL: https://jenkins-csb-openshift-qe-mastern.dno.corp.redhat.com/job/ocp-common/job/Flexy-install/$1/artifact/workdir/install-dir/auth/kubeconfig
- Target kubeconfig path: /Users/hongyli/projects/coo_test/kubeconfig-$1
- Installation script: /Users/hongyli/projects/coo_test/install/install_coo_prod.sh
- Working directory: /Users/hongyli/projects/coo_test

## Implementation Steps

1. Change to the coo_test directory: /Users/hongyli/projects/coo_test
2. Download the kubeconfig artifact from Jenkins job $1 using curl with -k flag
3. Save it as kubeconfig-$1 in the current directory
4. Export KUBECONFIG environment variable pointing to the downloaded file
5. Run the COO production installation script: ./install/install_coo_prod.sh

## Important Notes

- Use curl with -k flag to ignore SSL certificate verification
- Ensure the KUBECONFIG export persists for the installation script execution
- The installation script will create the operator namespace and deploy COO
- Wait for the operator to become ready before completing
