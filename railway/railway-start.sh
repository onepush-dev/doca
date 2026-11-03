#!/usr/bin/env bash
# Railway start wrapper for Doca (runs as root, drops to the image's node user).
set -euo pipefail
if [ "$(id -u)" = 0 ]; then
  mkdir -p /data/storage /data/plugins
  if [ "$(stat -c %U /data)" != node ] || [ "$(stat -c %U /data/storage)" != node ]; then
    chown -R node:node /data
  fi
  exec setpriv --reuid=node --regid=node --init-groups env HOME=/home/node bash "$0" "$@"
fi
if [ -z "${DOCA_ORIGIN:-}" ] || [ "${DOCA_ORIGIN}" = "https://" ]; then
  if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then DOCA_ORIGIN="https://${RAILWAY_PUBLIC_DOMAIN}"
  else echo "DOCA_ORIGIN is not set and the service has no public domain" >&2; exit 1; fi
fi
export DOCA_ORIGIN
export DOCA_PORT="${PORT:-39120}" DOCA_HOST="${DOCA_HOST:-0.0.0.0}"
if [ -z "${DOCA_CREDENTIAL_MASTER_KEY:-}" ]; then
  echo "DOCA_CREDENTIAL_MASTER_KEY is required (64 hex chars, keep it forever)" >&2; exit 1
fi
cd /app
node --import tsx apps/server/src/main.ts &
pid=$!
trap 'kill -TERM "$pid" 2>/dev/null' TERM INT
if [ -n "${DOCA_ADMIN_PASSWORD:-}" ]; then
  (
    for _ in $(seq 1 180); do
      if node -e "require('http').get('http://127.0.0.1:'+process.env.DOCA_PORT+'/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"; then
        out=$(DOCA_BOOTSTRAP_LOGIN="${DOCA_ADMIN_LOGIN:-admin}" DOCA_BOOTSTRAP_PASSWORD="$DOCA_ADMIN_PASSWORD" \
              node --import tsx apps/server/src/bootstrap/admin.ts 2>&1) && echo "[railway] administrator '${DOCA_ADMIN_LOGIN:-admin}' created" \
          || { if grep -q '管理员已初始化' <<<"$out"; then echo "[railway] administrator already exists, DOCA_ADMIN_* ignored"; else echo "[railway] admin bootstrap failed: $out" >&2; fi; }
        exit 0
      fi
      sleep 1
    done
    echo "[railway] Doca did not become healthy in time; admin bootstrap skipped" >&2
  ) &
fi
set +e
wait "$pid"; code=$?
while kill -0 "$pid" 2>/dev/null; do wait "$pid"; code=$?; done
exit $code
