# Currency Monitor (React + PostgreSQL)

Проект мониторит изменение курса валют:
- забирает данные из API,
- сохраняет историю в PostgreSQL,
- показывает графики в React,
- отправляет уведомления при резких изменениях,
- содержит мини-окно ИИ-ассистента.

## Архитектура

- `backend` — Express API + cron-синхронизация + PostgreSQL
- `frontend` — React (Vite) + Recharts + SSE-уведомления
- `docker-compose.yml` — PostgreSQL (образ с **TLS** + `pg_hba`, см. **`postgres/README.md`**)
- `infra/` — отдельный стек: Nginx, Prometheus, Grafana, Alertmanager, Node Exporter, Jenkins, Telegram-бот, **n8n** (автоматизация), Terraform, Ansible (см. `infra/README.md`, `infra/n8n/README.md`, раздел ниже)
- **Безопасность:** `infra/security/README.md`, `docker-compose.secure.yml` (TLS + Nginx reverse proxy, БД без публ. порта, админ-пользователи, бэкап/UFW/Fail2Ban/SSH — шаблоны и скрипты)

## Серверлік инфрақұрылым (Terraform, Ansible, Bash)

| Компонент | Где | Запуск |
|-----------|-----|--------|
| **Terraform** | `infra/terraform/` | `./tf-plan.sh` или `cd infra/terraform && terraform init && terraform plan` |
| **Ansible** | `infra/ansible/` (`site.yml`, роли `common`, `docker_tools`) | `./ansible-site.sh` или `cd infra/ansible && ansible-playbook site.yml` |
| **Деплой приложения** | `docker-compose.yml` в корне | `./deploy-app.sh` |
| **Деплой infra-стека** | `infra/docker-compose.yml` | Сначала `cp infra/env.example infra/.env`, затем `./deploy-infra.sh` |
| **Бэкап PostgreSQL** | дамп в `backups/` | `./backup-postgres.sh` (нужен запущенный контейнер `currency-postgres`) |

Подробнее: `infra/terraform/README.md`, `infra/ansible/README.md`.

## Git

Репозиторий в корне проекта, ветка по умолчанию **`main`**. Секреты не коммитятся (см. `.gitignore`: `.env`, `backend/.env`, `infra/.env`, `.env.secure`, `backups/`, сертификаты и т.д.).

**Выложить на GitHub:** создайте пустой репозиторий на github.com, затем:

```bash
cd /home/zarina/Загрузки/MPC/MPC
git remote add origin https://github.com/ВАШ_ЛОГИН/currency-monitor.git
git push -u origin main
```

Для SSH замените URL на `git@github.com:ВАШ_ЛОГИН/currency-monitor.git`. Jenkins: задайте `JENKINS_GIT_URL` в `infra/.env` на этот URL (см. `infra/jenkins/README.md`).

## Быстрый старт

1. Запустите БД:

```bash
docker compose up -d
```

2. Подготовьте env:

```bash
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
```

3. Установите зависимости и запустите backend:

```bash
cd backend
npm install
npm run dev
```

4. В отдельном терминале запустите frontend:

```bash
cd frontend
npm install
npm run dev
```

5. Откройте `http://localhost:5173`.

## Основные endpoint'ы backend

- `GET /api/config` — конфигурация валют
- `GET /api/rates/latest` — последние курсы
- `GET /api/rates/history/:quote?hours=24` — история по валюте
- `GET /api/alerts` — последние алерты
- `GET /api/alerts/stream` — поток алертов (SSE)
- `GET /api/rates/stream` — поток новых значений курсов для графика (SSE, real-time в UI)
- `POST /api/assistant` — мини ИИ-ассистент (Ollama + fallback на локальную логику)

## Как работает алерт

При каждом цикле синхронизации backend сравнивает новую цену с предыдущей.
Если процент изменения `>= ALERT_THRESHOLD_PERCENT`, событие:
- сохраняется в таблицу `alerts`;
- отправляется в UI через SSE.

## Реальное время и официальный источник

- Источник курсов: официальный ECB feed: `https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml`.
- UI обновляет график и карточки курсов без перезагрузки через `GET /api/rates/stream`.
- Частота опроса источника на backend задается `SYNC_CRON` (по умолчанию каждые 15 секунд).
- Важно: ECB reference rates обычно обновляются 1 раз в рабочий день, поэтому внутри дня значение может не меняться.

### Режим 15 секунд (крипто-пары)

Если нужны пары, которые меняются каждые 15 секунд, переключите источник на Binance Spot:

```env
SOURCE_MODE=BINANCE_CRYPTO
BASE_CURRENCY=USDT
BINANCE_SYMBOLS=BTCUSDT,ETHUSDT,SOLUSDT,BNBUSDT
SYNC_CRON=*/15 * * * * *
```

В этом режиме в UI пары отображаются как `BTC/USDT`, `ETH/USDT` и т.д.

### Режим официального дневного FX

```env
SOURCE_MODE=ECB
BASE_CURRENCY=USD
QUOTE_CURRENCIES=EUR,KZT,GBP,CNY,JPY
SYNC_CRON=*/15 * * * * *
```

Backend продолжает собирать и сохранять точки в БД по cron даже если сайт закрыт, поэтому после возврата вы видите накопленную историю изменений.

## ИИ-ассистент (Ollama / qwen)

Backend отправляет запрос в локальный Ollama через endpoint `/api/chat`.

Для включения укажите в `backend/.env`:

```env
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=qwen3.5-cloud
```

Перед запуском backend убедитесь, что Ollama запущен и модель загружена:

```bash
ollama pull qwen3.5-cloud
ollama run qwen3.5-cloud
```

Если Ollama недоступен, используется локальный fallback-ответ по данным из БД.

## Источники данных

- ECB reference rates XML: https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml
- Binance Spot public API (`/api/v3/ticker/price`): https://api.binance.com/api/v3/ticker/price
