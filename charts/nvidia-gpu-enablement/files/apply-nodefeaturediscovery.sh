#!/bin/bash
set -euo pipefail

MANIFEST="/config/nodefeaturediscovery.yaml"

echo "Waiting for NodeFeatureDiscovery API..."
until oc apply -f "${MANIFEST}" >/dev/null 2>&1; do
  sleep 10
done

echo "NodeFeatureDiscovery applied"
