#!/usr/bin/env bash
# Ansible: проверка хоста (localhost) — docker, compose, df.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT/infra/ansible"
ansible-playbook site.yml "$@"
