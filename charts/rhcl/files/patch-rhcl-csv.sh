#!/bin/bash
set -euo pipefail

CSV_NAME="${RHCL_CSV:?RHCL_CSV required}"
NAMESPACE="${RHCL_NAMESPACE:?RHCL_NAMESPACE required}"
GATEWAY_CONTROLLERS="${ISTIO_GATEWAY_CONTROLLER_NAMES:?ISTIO_GATEWAY_CONTROLLER_NAMES required}"

echo "Waiting for CSV ${CSV_NAME} in ${NAMESPACE}..."
until oc get csv "${CSV_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; do
  sleep 5
done

ENV_INDEX=$(oc get csv "${CSV_NAME}" -n "${NAMESPACE}" -o json | \
  jq -r '.spec.install.spec.deployments[0].spec.template.spec.containers[0].env | map(.name) | index("ISTIO_GATEWAY_CONTROLLER_NAMES")')

if [ "${ENV_INDEX}" = "null" ]; then
  echo "ISTIO_GATEWAY_CONTROLLER_NAMES not found in CSV ${CSV_NAME}" >&2
  exit 1
fi

CURRENT=$(oc get csv "${CSV_NAME}" -n "${NAMESPACE}" -o json | \
  jq -r ".spec.install.spec.deployments[0].spec.template.spec.containers[0].env[${ENV_INDEX}].value")

if [ "${CURRENT}" = "${GATEWAY_CONTROLLERS}" ]; then
  echo "CSV already patched"
  exit 0
fi

oc patch csv "${CSV_NAME}" -n "${NAMESPACE}" --type=json -p \
  "[{\"op\":\"replace\",\"path\":\"/spec/install/spec/deployments/0/spec/template/spec/containers/0/env/${ENV_INDEX}/value\",\"value\":\"${GATEWAY_CONTROLLERS}\"}]"

echo "Patched ISTIO_GATEWAY_CONTROLLER_NAMES on ${CSV_NAME}"
