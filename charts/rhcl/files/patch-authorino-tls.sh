#!/bin/bash
set -euo pipefail

NAMESPACE="${KUADRANT_NAMESPACE:-kuadrant-system}"
SECRET="${AUTHORINO_CERT_SECRET:-authorino-server-cert}"

echo "Waiting for Authorino/authorino in ${NAMESPACE}..."
until oc get authorino authorino -n "${NAMESPACE}" >/dev/null 2>&1; do
  sleep 5
done

echo "Patching Authorino TLS spec in ${NAMESPACE}..."
oc patch authorino authorino -n "${NAMESPACE}" --type=merge -p \
  "{\"spec\":{\"clusterWide\":true,\"healthz\":{},\"listener\":{\"ports\":{},\"tls\":{\"certSecretRef\":{\"name\":\"${SECRET}\"},\"enabled\":true}},\"oidcServer\":{\"tls\":{\"enabled\":true,\"certSecretRef\":{\"name\":\"${SECRET}\"}}}}}"
