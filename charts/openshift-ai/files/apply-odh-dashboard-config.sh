#!/bin/bash
set -euo pipefail

MANIFEST="/config/odh-dashboard-config.yaml"

echo "Waiting for OdhDashboardConfig API..."
while true; do
  if output=$(oc apply -f "${MANIFEST}" 2>&1); then
    echo "${output}"
    break
  fi
  echo "${output}"
  sleep 10
done

echo "OdhDashboardConfig applied"
