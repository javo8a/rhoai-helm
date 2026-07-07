# Tech Stack

- Helm 3 (apiVersion v2, type: application)
- Kubernetes / OpenShift CRs: OLM Subscriptions, CSVs, DSC/DSCI, Gateway API, Kuadrant, LLMInferenceService, MaaS CRs
- Bash post-install Jobs in charts/*/files/*.sh using oc + jq from global.toolsImage
- YAML templates + values only; no app runtime code

## Shared subchart

charts/install-operators: OLM Subscriptions + Manual InstallPlan approval Jobs; aliased per parent (install-rhoai in openshift-ai).

## Default operator pins (override per cluster)

- RHOAI: rhods-operator.3.4.0, channel stable-3.x
- Service Mesh 3: servicemeshoperator3.v3.3.3
- RHCL: rhcl-operator.v1.3.4
- OpenTelemetry: opentelemetry-operator.v0.144.0-3

## External references

- Pattern: openshift-setup (jharmison-redhat)
- Kustomize parity: ../rhoai-3_4/ (outside repo root)

## Cluster tooling

global.toolsImage must provide oc and jq (default: openshift/tools:latest in-cluster).