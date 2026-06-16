#!/bin/bash
set -euo pipefail

MANIFEST="/config/clusterpolicy.yaml"

echo "Waiting for ClusterPolicy API..."
until oc apply -f "${MANIFEST}" >/dev/null 2>&1; do
  sleep 10
done

echo "ClusterPolicy applied"
