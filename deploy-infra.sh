#!/usr/bin/env bash
# Поднимает стек наблюдаемости из infra/docker-compose.yml.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT/infra"
if [[ ! -f .env ]]; then
  echo "Создайте infra/.env: cp env.example .env" >&2
  exit 1
fi
docker compose up -d --build "$@"
