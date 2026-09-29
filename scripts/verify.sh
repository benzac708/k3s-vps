#!/usr/bin/env bash
set -euo pipefail

actionlint
bash -n install.sh scripts/*.sh
shellcheck -S warning install.sh scripts/*.sh
uvx --from yamllint==1.38.0 yamllint -c .yamllint.yml \
  tls/cluster-issuer.yaml \
  .github/
gitleaks detect --source . --redact --no-banner --exit-code 1

kubeconform \
  -strict \
  -kubernetes-version 1.36.0 \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  tls/cluster-issuer.yaml

# Trivy runs as the dedicated CI step in the workflow.