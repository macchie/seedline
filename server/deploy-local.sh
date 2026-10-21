#!/usr/bin/env bash
# Copies the Seedline Lua module into a running local Nakama container and restarts it.
# Usage: server/deploy-local.sh [container-name]
set -euo pipefail

CONTAINER="${1:-nakama}"
HERE="$(cd "$(dirname "$0")" && pwd)"

docker exec "$CONTAINER" mkdir -p /nakama/data/modules 2>/dev/null || true
docker cp "$HERE/nakama/modules/seedline.lua" "$CONTAINER:/nakama/data/modules/seedline.lua"
docker restart "$CONTAINER" >/dev/null

for _ in $(seq 1 60); do
  if curl -fs http://localhost:7350/healthcheck >/dev/null; then
    echo "Nakama is healthy"
    docker logs --tail 200 "$CONTAINER" 2>&1 | grep -E "Seedline module loaded|runtime|lua" | tail -n 5 || true
    exit 0
  fi
  sleep 1
done
echo "Nakama did not become healthy" >&2
exit 1
