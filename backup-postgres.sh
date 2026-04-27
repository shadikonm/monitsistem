#!/usr/bin/env bash
# Дамп БД currency_db из контейнера currency-postgres в каталог backups/.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$ROOT/backups"
mkdir -p "$OUT_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$OUT_DIR/currency_db-${STAMP}.sql"
if ! docker ps --format '{{.Names}}' | grep -qx 'currency-postgres'; then
  echo "Контейнер currency-postgres не запущен. Сначала: ./deploy-app.sh" >&2
  exit 1
fi
docker exec currency-postgres pg_dump -U postgres --no-owner currency_db >"$OUT"
echo "Сохранено: $OUT"
