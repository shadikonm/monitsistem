#!/usr/bin/env bash
# Terraform: init + plan (локальные провайдеры random/tls/local).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT/infra/terraform"
terraform init -input=false
set +e
terraform plan -input=false -out=tfplan.binary
ec=$?
set -e
# 0 — без изменений, 2 — есть изменения (успех для CI/ручной проверки)
if [[ "$ec" -eq 0 || "$ec" -eq 2 ]]; then
  echo "План в tfplan.binary. Применить: terraform apply tfplan.binary"
  exit 0
fi
exit "$ec"
