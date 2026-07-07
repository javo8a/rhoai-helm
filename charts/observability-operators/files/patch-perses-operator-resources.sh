#!/bin/bash
set -euo pipefail

NAMESPACE="${PERSES_NAMESPACE:?PERSES_NAMESPACE required}"
DEPLOYMENT="${PERSES_DEPLOYMENT:-perses-operator}"
CONTAINER="${PERSES_CONTAINER:-manager}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-900}"
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

resolve_container_index() {
  local idx

  idx=$(oc get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o json | \
    jq -r --arg name "${CONTAINER}" '
      (.spec.template.spec.containers | map(.name) | index($name)) as $i |
      if $i == null then empty else ($i | tostring) end')

  if [ -n "${idx}" ]; then
    echo "${idx}"
    return 0
  fi

  if [ "$(oc get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o json | jq '.spec.template.spec.containers | length')" = "1" ]; then
    echo "0"
    return 0
  fi

  echo "Error: container ${CONTAINER} not found in ${DEPLOYMENT}" >&2
  exit 1
}

wait_for "${DEPLOYMENT} in ${NAMESPACE}" "oc get deployment \"${DEPLOYMENT}\" -n \"${NAMESPACE}\""

CONTAINER_IDX=$(resolve_container_index)
CONTAINER_NAME=$(oc get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o json | \
  jq -r ".spec.template.spec.containers[${CONTAINER_IDX}].name")

CURRENT=$(oc get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" -o json | \
  jq -c ".spec.template.spec.containers[${CONTAINER_IDX}].resources // {}")

if [ "${CURRENT}" = "${RESOURCES_JSON}" ]; then
  echo "${DEPLOYMENT} resources already set"
  exit 0
fi

echo "Patching ${DEPLOYMENT}/${CONTAINER_NAME} resources (request memory=${MEMORY_REQUEST}, limit memory=${MEMORY_LIMIT})..."
oc patch deployment "${DEPLOYMENT}" -n "${NAMESPACE}" --type=json -p \
  "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/${CONTAINER_IDX}/resources\",\"value\":${RESOURCES_JSON}}]"

echo "Perses operator resources patched"
