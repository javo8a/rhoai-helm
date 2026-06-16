#!/bin/bash
set -euo pipefail

NAMESPACE="${KUADRANT_NAMESPACE:-kuadrant-system}"
DEPLOYMENT="kuadrant-operator-controller-manager"

echo "Waiting for ${DEPLOYMENT} in ${NAMESPACE}..."
until oc get deployment "${DEPLOYMENT}" -n "${NAMESPACE}" >/dev/null 2>&1; do
  sleep 5
done

echo "Restarting ${DEPLOYMENT} in ${NAMESPACE}..."
oc delete pod -n "${NAMESPACE}" -l control-plane=controller-manager --wait=false
sleep 5
oc rollout status -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" --timeout=300s
