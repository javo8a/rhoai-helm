#!/bin/bash
set -euo pipefail

NAMESPACE="${KUADRANT_NAMESPACE:-kuadrant-system}"
SERVICE="authorino-authorino-authorization"
SECRET="${AUTHORINO_CERT_SECRET:-authorino-server-cert}"

echo "Waiting for Service/${SERVICE} in ${NAMESPACE}..."
until oc get service "${SERVICE}" -n "${NAMESPACE}" >/dev/null 2>&1; do
  sleep 5
done

echo "Annotating ${SERVICE} with serving cert secret ${SECRET}..."
oc patch service "${SERVICE}" -n "${NAMESPACE}" --type=merge -p \
  "{\"metadata\":{\"annotations\":{\"service.beta.openshift.io/serving-cert-secret-name\":\"${SECRET}\"}}}"
