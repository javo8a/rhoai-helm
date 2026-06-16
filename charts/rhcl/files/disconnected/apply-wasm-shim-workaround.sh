#!/bin/bash
set -euo pipefail

WASM_SHIM_IMAGE="${WASM_SHIM_IMAGE:?WASM_SHIM_IMAGE required}"
PROTECTED_REGISTRY="${PROTECTED_REGISTRY:?PROTECTED_REGISTRY required}"

echo "Waiting for rhcl-operator subscription in kuadrant-system..."
until oc get subscription rhcl-operator -n kuadrant-system >/dev/null 2>&1; do
  sleep 5
done

echo "Creating wasm-plugin-pull-secret in openshift-ingress..."
oc get secret pull-secret -n openshift-config -o json | \
  jq '.metadata.namespace = "openshift-ingress" |
      .metadata.name = "wasm-plugin-pull-secret" |
      del(.metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.managedFields)' | \
  oc apply -f -

echo "Patching rhcl-operator subscription with internal WASM shim image..."
oc patch subscription rhcl-operator -n kuadrant-system --type merge -p "{
  \"spec\": {
    \"config\": {
      \"env\": [
        {
          \"name\": \"RELATED_IMAGE_WASMSHIM\",
          \"value\": \"${WASM_SHIM_IMAGE}\"
        },
        {
          \"name\": \"PROTECTED_REGISTRY\",
          \"value\": \"${PROTECTED_REGISTRY}\"
        }
      ]
    }
  }
}"

echo "WASM shim workaround applied"
