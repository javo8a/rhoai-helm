#!/bin/bash
set -euo pipefail

MANIFEST="/config/dsc.yaml"

echo "Waiting for DataScienceCluster API..."
while true; do
  if output=$(oc apply -f "${MANIFEST}" 2>&1); then
    echo "${output}"
    break
  fi
  echo "${output}"
  sleep 10
done

echo "DataScienceCluster applied"
