# Suggested Commands

## New cluster setup

```bash
cp -r clusters/example.cluster.opentlc.com clusters/mycluster.mydomain.com
# edit clusters/mycluster.../cluster.yaml (name, baseDomain, toolsImage, disconnected, maas.postgres)
```

## Chart dependencies (required before helm template/install for charts using install-operators)

```bash
for c in cert-manager nvidia-gpu-enablement rhcl leaderworkerset openshift-ai observability-operators service-mesh-operators; do
  (cd charts/$c && helm dependency update)
done
```

## Render without install

```bash
CLUSTER=clusters/example.cluster.opentlc.com
helm template test charts/openshift-ai \
  -f $CLUSTER/cluster.yaml \
  -f $CLUSTER/platform/values/openshift-ai/values.yaml
```

## Wave install (example wave 5)

```bash
CLUSTER=clusters/example.cluster.opentlc.com
helm upgrade --install openshift-ai charts/openshift-ai -n redhat-ods-operator --create-namespace \
  -f $CLUSTER/cluster.yaml -f $CLUSTER/platform/values/openshift-ai/values.yaml
```

Full wave sequence: see README.md install section.

## Kustomize parity check

```bash
helm template test charts/gateway-api -f $CLUSTER/cluster.yaml -f $CLUSTER/platform/values/gateway-api/values.yaml | grep -A5 "kind: Gateway"
kustomize build ../rhoai-3_4/overlays/03-gateway | grep -A5 "kind: Gateway"
```

## Cluster debug (post-install Jobs)

```bash
oc get jobs -n redhat-ods-applications
oc logs job/apply-dsc -n redhat-ods-applications
oc get dsc,dsci -A
```

## Serena memory maintenance

```bash
serena memories check   # from project root; validates memory references
```