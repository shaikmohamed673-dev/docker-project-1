#!/usr/bin/env bash
# One-command deploy:  ./scripts/deploy.sh
set -euo pipefail
cd "$(dirname "$0")/.."

command -v docker >/dev/null || { echo "Docker not installed"; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose v2 missing"; exit 1; }

if [ ! -f .env ]; then
  cp .env.example .env
  echo ">> .env created from template. EDIT the password, then run again."
  exit 1
fi

PORT=$(grep -E '^WEB_PORT=' .env | cut -d= -f2)
PORT=${PORT:-8080}

echo ">> Building images..."
docker compose build

echo ">> Starting containers..."
docker compose up -d

echo ">> Waiting for services..."
for i in $(seq 1 30); do
  if curl -fs "http://localhost:${PORT}/api/health" >/dev/null 2>&1; then
    echo ">> App is UP at http://localhost:${PORT}"; docker compose ps; exit 0
  fi
  sleep 2
done
echo ">> Not healthy in time. Logs:"; docker compose logs --tail=50; exit 1
