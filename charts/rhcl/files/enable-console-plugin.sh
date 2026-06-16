#!/bin/bash
set -euo pipefail

PLUGIN="${CONSOLE_PLUGIN:?CONSOLE_PLUGIN required}"

if oc get console.operator.openshift.io cluster -o json | \
  jq -e --arg p "${PLUGIN}" '.spec.plugins[]? | select(. == $p)' >/dev/null; then
  echo "Console plugin ${PLUGIN} already enabled"
  exit 0
fi

oc patch console.operator.openshift.io cluster --type=json \
  -p "[{\"op\":\"add\",\"path\":\"/spec/plugins/-\",\"value\":\"${PLUGIN}\"}]"

echo "Enabled console plugin ${PLUGIN}"
