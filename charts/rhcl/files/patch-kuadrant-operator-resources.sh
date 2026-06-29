#!/bin/bash
set -euo pipefail

NAMESPACE="${KUADRANT_NAMESPACE:?KUADRANT_NAMESPACE required}"
DEPLOYMENT="${KUADRANT_CONTROLLER_DEPLOYMENT:-kuadrant-operator-controller-manager}"
CSV_NAME="${RHCL_CSV:-}"
MEMORY_REQUEST="${CONTROLLER_MEMORY_REQUEST:?CONTROLLER_MEMORY_REQUEST required}"
MEMORY_LIMIT="${CONTROLLER_MEMORY_LIMIT:?CONTROLLER_MEMORY_LIMIT required}"
CPU_REQUEST="${CONTROLLER_CPU_REQUEST:?CONTROLLER_CPU_REQUEST required}"
CPU_LIMIT="${CONTROLLER_CPU_LIMIT:?CONTROLLER_CPU_LIMIT required}"

RESOURCES_JSON=$(jq -n \
  --arg mr "${MEMORY_REQUEST}" \
  --arg ml "${MEMORY_LIMIT}" \
  --arg cr "${CPU_REQUEST}" \
  --arg cl "${CPU_LIMIT}" \
  '{requests: {memory: $mr, cpu: $cr}, limits: {memory: $ml, cpu: $cl}}')

echo "Waiting for ${DEPLOYMENT} in ${NAMESPACE}..."
until oc get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" >/dev/null 2>&1; do
  sleep 5
done

CURRENT=$(oc get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o json | \
  jq -c '.spec.template.spec.containers[] | select(.name == "manager") | .resources // {}')

if [ "${CURRENT}" = "${RESOURCES_JSON}" ]; then
  echo "${DEPLOYMENT} resources already set"
else
  echo "Patching ${DEPLOYMENT} resources (request memory=${MEMORY_REQUEST}, limit memory=${MEMORY_LIMIT})..."
  oc patch deployment "${DEPLOYMENT}" -n "${NAMESPACE}" --type=merge -p "$(jq -n \
    --argjson resources "${RESOURCES_JSON}" \
    '{spec: {template: {spec: {containers: [{name: "manager", resources: $resources}]}}}}')"
fi

if [ -n "${CSV_NAME}" ]; then
  echo "Waiting for CSV ${CSV_NAME} in ${NAMESPACE}..."
  until oc get csv "${CSV_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; do
    sleep 5
  done

  DEPLOY_IDX=$(oc get csv "${CSV_NAME}" -n "${NAMESPACE}" -o json | \
    jq -r --arg name "${DEPLOYMENT}" '.spec.install.spec.deployments | map(.name) | index($name)')

  if [ "${DEPLOY_IDX}" = "null" ]; then
    echo "Warning: ${DEPLOYMENT} not found in CSV ${CSV_NAME}; deployment patch only" >&2
    exit 0
  fi

  CSV_CURRENT=$(oc get csv "${CSV_NAME}" -n "${NAMESPACE}" -o json | \
    jq -c ".spec.install.spec.deployments[${DEPLOY_IDX}].spec.template.spec.containers[0].resources // {}")

  if [ "${CSV_CURRENT}" = "${RESOURCES_JSON}" ]; then
    echo "CSV resources already set"
  else
    echo "Patching CSV ${CSV_NAME} deployment index ${DEPLOY_IDX}..."
    oc patch csv "${CSV_NAME}" -n "${NAMESPACE}" --type=json -p \
      "[{\"op\":\"replace\",\"path\":\"/spec/install/spec/deployments/${DEPLOY_IDX}/spec/template/spec/containers/0/resources\",\"value\":${RESOURCES_JSON}}]"
  fi
fi

echo "Kuadrant controller resources patched"
