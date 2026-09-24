#!/usr/bin/env bash
set -euo pipefail

actionlint
bash -n install.sh platform/bootstrap.sh scripts/*.sh
shellcheck -S warning install.sh platform/bootstrap.sh scripts/*.sh
uvx --from yamllint==1.38.0 yamllint -c .yamllint.yml \
  platform/ai-platform.yaml \
  platform/ollama.yaml \
  platform/ai-platform-default-deny.yaml \
  platform/ollama-access.yaml \
  tls/cluster-issuer.yaml \
  .github/
gitleaks detect --source . --redact --no-banner --exit-code 1

kubeconform \
  -strict \
  -kubernetes-version 1.36.0 \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  platform/ai-platform.yaml \
  platform/ollama.yaml \
  platform/ai-platform-default-deny.yaml \
  platform/ollama-access.yaml \
  tls/cluster-issuer.yaml

TRIVY_CACHE_DIR="${TRIVY_CACHE_DIR:-$PWD/.trivy-cache}"
export TRIVY_CACHE_DIR
trivy fs \
  --scanners vuln,misconfig,secret \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  .
