#!/bin/sh
# Starts the SigNoz OTel Collector once the ClickHouse schema exists.
set -eu

fail() { echo "FATAL: $*" >&2; exit 1; }

[ -n "${CLICKHOUSE_DSN:-}" ] || fail "CLICKHOUSE_DSN must be set (reference \${{clickhouse.CLICKHOUSE_DSN}})."
[ -n "${OTLP_PUBLIC_TOKEN:-}" ] || fail "OTLP_PUBLIC_TOKEN must be set; it protects the public OTLP listeners."

export SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_DSN="${SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_DSN:-$CLICKHOUSE_DSN}"
export LOW_CARDINAL_EXCEPTION_GROUPING="${LOW_CARDINAL_EXCEPTION_GROUPING:-false}"

# OpAMP lets SigNoz push log-pipeline changes to this collector.
SIGNOZ_HOST="${SIGNOZ_HOST:-}"
[ -n "$SIGNOZ_HOST" ] || SIGNOZ_HOST="signoz.railway.internal"
printf 'server_endpoint: ws://%s:4320/v1/opamp\n' "$SIGNOZ_HOST" > /var/tmp/opamp.yaml

# Waits (bounded by SIGNOZ_OTEL_COLLECTOR_TIMEOUT) until schema-migrator has run.
/signoz-otel-collector migrate sync check

exec /signoz-otel-collector \
  --config=/etc/signoz/collector.yaml \
  --manager-config=/var/tmp/opamp.yaml \
  --copy-path=/var/tmp/collector-config.yaml
