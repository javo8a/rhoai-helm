# Task Completion

No CI pipeline or Makefile. Validate manually before done.

## Required checks

1. helm dependency update on charts whose Chart.yaml dependencies changed
2. helm template for affected chart with example cluster values (CLUSTER=clusters/example.cluster.opentlc.com; platform charts use platform/values/, workload charts use values/)
3. New Jobs/scripts follow hook + RBAC pattern (see mem:conventions)
4. Parity-sensitive changes: compare helm template output vs Kustomize baseline per README

## Optional with cluster access

- helm upgrade --install for affected wave
- oc get jobs / oc logs job/name for post-install Jobs
- Confirm operator CSV Succeeded before next wave

## Not required unless asked

- No unit tests in repo
- helm lint optional
- Do not auto-commit or push

## Serena

After memory edits: serena memories check from project root