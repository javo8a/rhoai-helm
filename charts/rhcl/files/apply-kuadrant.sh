#!/bin/bash
set -euo pipefail

MANIFEST="/config/kuadrant.yaml"

echo "Waiting for Kuadrant API..."
while true; do
  if output=$(oc apply -f "${MANIFEST}" 2>&1); then
    echo "${output}"
    break
  fi
  echo "${output}"
  sleep 10
done

echo "Kuadrant applied"
