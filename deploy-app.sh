#!/usr/bin/env bash
# Поднимает основное приложение: PostgreSQL, API, Nginx (docker-compose.yml в корне).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
docker compose up -d --build "$@"
