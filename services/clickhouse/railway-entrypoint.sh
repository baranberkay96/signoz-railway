#!/bin/bash
# Thin wrapper around the official ClickHouse entrypoint.
# - Refuses to start without a password (the stock entrypoint then recreates
#   the `default` user with that password and network access from ::/0).
# - Falls back to the conventional private hostname of the Keeper service if
#   the reference variable is empty.
set -euo pipefail

if [ -z "${CLICKHOUSE_PASSWORD:-}" ]; then
  echo "FATAL: CLICKHOUSE_PASSWORD must be set." >&2
  exit 1
fi

: "${CLICKHOUSE_KEEPER_HOST:=clickhouse-keeper.railway.internal}"
export CLICKHOUSE_KEEPER_HOST

# Railway mounts fresh ext4 volumes with a lost+found directory; harmless for
# ClickHouse, but remove it so the data dir looks clean.
rm -rf /var/lib/clickhouse/lost+found 2>/dev/null || true

echo "railway: starting ClickHouse (keeper=${CLICKHOUSE_KEEPER_HOST})"
exec /entrypoint.sh "$@"
