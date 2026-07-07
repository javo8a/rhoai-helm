# Conventions

## Values layering (later wins)

Platform charts: `charts/{app}/values.yaml` → `clusters/{cluster}/cluster.yaml` → `clusters/{cluster}/platform/values/{app}/values.yaml`

Workload charts: same but `clusters/{cluster}/values/{app}/values.yaml` for wave 7–8.

## Operator-owned vs Helm-owned resources

- Declarative templates for resources Helm owns outright (Subscriptions, CRs, NetworkPolicies)
- **Post-install Jobs** for operator-created resources that need patching (Tenants, CSV env, ConfigMaps, OdhDashboardConfig)
- Job pattern: SA + Role(RBAC) + RoleBinding + ConfigMap(script) + Job; script in `charts/{chart}/files/`

## Job annotations (standard)

```yaml
helm.sh/hook: post-install,post-upgrade
helm.sh/hook-delete-policy: before-hook-creation
argocd.argoproj.io/sync-wave: "<N>"   # when ArgoCD-managed
argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true  # on SA/namespace prereqs
```

- `helm.sh/hook-weight` orders Jobs within a release (lower first)
- Scripts: `set -euo pipefail`, wait loops on `oc get` until resource exists, idempotent patches

## install-operators subchart

- Parent charts alias it (`install-rhoai`, etc.) with `condition: install-{alias}.enabled`
- Subscriptions use Manual InstallPlan approval via hook Job

## Naming

- Chart dirs: kebab-case (`openshift-ai`, `maas-subscriptions`)
- Job names match purpose: `apply-dsc`, `patch-rhcl-csv`, `patch-segment-key-config`
- OpenShift namespaces: `redhat-ods-operator`, `redhat-ods-applications`, `models-as-a-service`, `ai-models`

## Git / MR

- Conventional commits (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`)
- Reference GitLab issues as `#<number>` in commits/MR descriptions

## Scope discipline

- Match existing chart structure; minimal diffs
- Do not commit unless explicitly requested
- No unrelated refactors when fixing a single chart