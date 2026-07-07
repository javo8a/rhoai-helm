# Core

Helm deployment repo for **RHOAI 3.4** and **Models-as-a-Service (MaaS)** on OpenShift. Parity target: sibling Kustomize tree `rhoai-3_4/` and `bootstrap.sh` (imperative steps encoded as Helm Jobs).

## Layout

- `charts/` — reusable Helm charts (13 apps + shared `install-operators` subchart)
- `clusters/{cluster}/` — per-cluster config
  - `cluster.yaml` — globals (`global.cluster.*`, `global.toolsImage`, `disconnected`, `maas.postgres`)
  - `platform/values/{app}/values.yaml` — waves 1–6 platform charts
  - `values/{app}/values.yaml` — waves 7–8 workload charts

## Install waves (strict order; wait for operators + post-install Jobs between waves)

1. cert-manager, observability-operators
2. nvidia-gpu-enablement, leaderworkerset, rhcl
3. service-mesh-operators, gateway-api
4. maas-postgres
5. openshift-ai
6. maas-controller
7. llmisvc
8. maas-subscriptions

## Cross-chart contracts

- `llmisvc` model keys must match `maas-subscriptions` `modelRefs`, `subscriptions`, `authPolicies` names
- `maas-db-config` secret must exist in `redhat-ods-applications` before wave 5
- Gateway hostname: `maas.apps.{cluster.name}.{cluster.baseDomain}`
- Wave 5 sets `serviceMesh.managementState: Removed` on DSCI; SM3 operator installed separately in wave 3

## Memory graph

- Stack & deps: `mem:tech_stack`
- Commands: `mem:suggested_commands`
- Helm/Job patterns: `mem:conventions`
- Done criteria: `mem:task_completion`