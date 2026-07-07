#!/bin/bash
set -euo pipefail

NAMESPACE="${KUADRANT_NAMESPACE:?KUADRANT_NAMESPACE required}"
DEPLOYMENT="${KUADRANT_CONTROLLER_DEPLOYMENT:-kuadrant-operator-controller-manager}"
RHCL_SUBSCRIPTION="${RHCL_SUBSCRIPTION:-rhcl-operator}"
RHCL_CSV_FALLBACK="${RHCL_CSV:-}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-600}"
MEMORY_REQUEST="${CONTROLLER_MEMORY_REQUEST:?CONTROLLER_MEMORY_REQUEST required}"
MEMORY_LIMIT="${CONTROLLER_MEMORY_LIMIT:?CONTROLLER_MEMORY_LIMIT required}"
CPU_REQUEST="${CONTROLLER_CPU_REQUEST:?CONTROLLER_CPU_REQUEST required}"
CPU_LIMIT="${CONTROLLER_CPU_LIMIT:?CONTROLLER_CPU_LIMIT required}"

RESOURCES_JSON=$(jq -cn \
  --arg mr "${MEMORY_REQUEST}" \
  --arg ml "${MEMORY_LIMIT}" \
  --arg cr "${CPU_REQUEST}" \
  --arg cl "${CPU_LIMIT}" \
  '{requests: {memory: $mr, cpu: $cr}, limits: {memory: $ml, cpu: $cl}}')

resources_equal() {
  local current="$1"
  jq -e -n --argjson current "${current}" --argjson expected "${RESOURCES_JSON}" '$current == $expected' >/dev/null
}

wait_for() {
  local description="$1"
  local check_cmd="$2"
  local elapsed=0

  while ! eval "${check_cmd}" >/dev/null 2>&1; do
    if [ "${elapsed}" -ge "${WAIT_TIMEOUT}" ]; then
      echo "Timed out after ${WAIT_TIMEOUT}s waiting for ${description}" >&2
      exit 1
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done
}

resolve_rhcl_csv() {
  local current

  # Prefer the pinned CSV from chart values (csvPatch.csvName / startingCSV).
  if [ -n "${RHCL_CSV_FALLBACK}" ]; then
    if oc get csv "${RHCL_CSV_FALLBACK}" -n "${NAMESPACE}" >/dev/null 2>&1; then
      echo "${RHCL_CSV_FALLBACK}"
      return 0
    fi
    return 1
  fi

  current=$(oc get subscription "${RHCL_SUBSCRIPTION}" -n "${NAMESPACE}" -o jsonpath='{.status.currentCSV}' 2>/dev/null || true)
  if [ -n "${current}" ] && oc get csv "${current}" -n "${NAMESPACE}" >/dev/null 2>&1; then
    echo "${current}"
    return 0
  fi

  return 1
}

wait_for_rhcl_csv() {
  local elapsed=0

  while true; do
    if CSV_NAME=$(resolve_rhcl_csv); then
      echo "Using RHCL CSV ${CSV_NAME}"
      return 0
    fi
    if [ "${elapsed}" -ge "${WAIT_TIMEOUT}" ]; then
      if [ -n "${RHCL_CSV_FALLBACK}" ]; then
        echo "Timed out after ${WAIT_TIMEOUT}s waiting for pinned CSV ${RHCL_CSV_FALLBACK} (installed: $(oc get subscription "${RHCL_SUBSCRIPTION}" -n "${NAMESPACE}" -o jsonpath='{.status.currentCSV}' 2>/dev/null || echo unknown))" >&2
      else
        echo "Timed out after ${WAIT_TIMEOUT}s waiting for RHCL CSV from subscription ${RHCL_SUBSCRIPTION}" >&2
      fi
      exit 1
    fi
    echo "Waiting for RHCL CSV..."
    sleep 5
    elapsed=$((elapsed + 5))
  done
}

patch_csv_resources() {
  wait_for_rhcl_csv

  DEPLOY_IDX=$(oc get csv "${CSV_NAME}" -n "${NAMESPACE}" -o json | \
    jq -r --arg name "${DEPLOYMENT}" '
      (.spec.install.spec.deployments | map(.name) | index($name)) as $i |
      if $i == null then empty else ($i | tostring) end')

  if [ -z "${DEPLOY_IDX}" ]; then
    echo "Warning: ${DEPLOYMENT} not found in CSV ${CSV_NAME}; skipping CSV patch" >&2
    return 0
  fi

  CSV_CURRENT=$(oc get csv "${CSV_NAME}" -n "${NAMESPACE}" -o json | \
    jq -c ".spec.install.spec.deployments[${DEPLOY_IDX}].spec.template.spec.containers[0].resources // {}")

  if resources_equal "${CSV_CURRENT}"; then
    echo "CSV resources already set"
    return 0
  fi

  echo "Patching CSV ${CSV_NAME} deployment index ${DEPLOY_IDX}..."
  oc patch csv "${CSV_NAME}" -n "${NAMESPACE}" --type=json -p \
    "[{\"op\":\"replace\",\"path\":\"/spec/install/spec/deployments/${DEPLOY_IDX}/spec/template/spec/containers/0/resources\",\"value\":${RESOURCES_JSON}}]"
}

patch_deployment_resources() {
  wait_for "${DEPLOYMENT} in ${NAMESPACE}" "oc get deployment \"${DEPLOYMENT}\" -n \"${NAMESPACE}\""

  CURRENT=$(oc get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o json | \
    jq -c '.spec.template.spec.containers[] | select(.name == "manager") | .resources // {}')

  CONTAINER_IDX=$(oc get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o json | \
    jq -r '
      (.spec.template.spec.containers | map(.name) | index("manager")) as $i |
      if $i == null then empty else ($i | tostring) end')

  if [ -z "${CONTAINER_IDX}" ]; then
    echo "Error: manager container not found in ${DEPLOYMENT}" >&2
    exit 1
  fi

  if resources_equal "${CURRENT}"; then
    echo "${DEPLOYMENT} resources already set"
    return 0
  fi

  echo "Patching ${DEPLOYMENT} resources (request memory=${MEMORY_REQUEST}, limit memory=${MEMORY_LIMIT})..."
  oc patch deployment "${DEPLOYMENT}" -n "${NAMESPACE}" --type=json -p \
    "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/${CONTAINER_IDX}/resources\",\"value\":${RESOURCES_JSON}}]"
}

patch_csv_resources
patch_deployment_resources

echo "Kuadrant controller resources patched"
