#!/bin/bash
set -euo pipefail

NAMESPACE="${MAAS_NAMESPACE:-models-as-a-service}"
TENANT="${MAAS_TENANT:-default-tenant}"

echo "Waiting for Tenant/${TENANT} in ${NAMESPACE}..."
until oc get tenant "${TENANT}" -n "${NAMESPACE}" >/dev/null 2>&1; do
  sleep 5
done

echo "Enabling telemetry on ${TENANT}..."
oc patch tenant "${TENANT}" -n "${NAMESPACE}" --type merge -p '{
  "spec": {
    "telemetry": {
      "enabled": true,
      "metrics": {
        "captureOrganization": true,
        "captureUser": false,
        "captureGroup": false,
        "captureModelUsage": true
      }
    }
  }
}'
