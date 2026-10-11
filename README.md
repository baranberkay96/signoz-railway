# Deploy and Host SigNoz with Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/signoz-v0145-apm-for-railway-apps?referralCode=20H68q)

SigNoz is an open-source, OpenTelemetry-native observability platform for application traces, metrics and logs. This community template runs the complete self-hosted stack on Railway — UI, OTel Collector, ClickHouse and ClickHouse Keeper — so the other services in your project can send telemetry over the private network within minutes.

## About Hosting SigNoz

A working SigNoz installation is more than one container. Telemetry arrives at the SigNoz OpenTelemetry Collector, which writes it into ClickHouse; ClickHouse needs ClickHouse Keeper for its replicated tables and cluster DDL; a one-shot migrator creates and upgrades the schema; and the SigNoz server provides the query API, dashboards, alerting and the web UI. This template wires all of that together with pinned versions, generated credentials, persistent volumes and health checks. The admin account is created from variables, public OTLP endpoints are protected by a bearer token, and services inside your Railway project can send data to the collector's private address without any token.

## Common Use Cases

- Trace requests across the APIs, workers and queues you run on Railway and find slow or failing spans.
- Centralise application logs and correlate them with traces and metrics.
- Track RED metrics (rate, errors, duration) per service and alert on them by email, Slack or webhook.
- Replace a per-host SaaS APM bill with a self-hosted stack you control.
- Monitor LLM and agent workloads instrumented with OpenTelemetry.

## Dependencies for SigNoz Hosting

- SigNoz server (`signoz/signoz`) with a SQLite metadata store on a volume
- SigNoz OpenTelemetry Collector (`signoz/signoz-otel-collector`) for ingest and schema migrations
- ClickHouse (`clickhouse/clickhouse-server`) as the telemetry store
- ClickHouse Keeper (`clickhouse/clickhouse-keeper`) for coordination

### Deployment Dependencies

- SigNoz documentation: https://signoz.io/docs/
- SigNoz self-host install (Foundry): https://signoz.io/docs/install/docker/
- SigNoz releases: https://github.com/SigNoz/signoz/releases
- SigNoz OTel Collector: https://github.com/SigNoz/signoz-otel-collector
- ClickHouse Keeper: https://clickhouse.com/docs/guides/sre/keeper/clickhouse-keeper
- OpenTelemetry SDK configuration: https://opentelemetry.io/docs/languages/sdk-configuration/otlp-exporter/

### Implementation Details

| Service | Image / build | Role | Public |
|---|---|---|---|
| `signoz` | `signoz/signoz:v0.145.0` | UI, query API, alerts | HTTPS domain |
| `otel-collector` | `signoz/signoz-otel-collector:v0.144.13` + config | OTLP ingest | HTTPS domain (OTLP/HTTP) and TCP proxy (OTLP/gRPC), token required |
| `schema-migrator` | `signoz/signoz-otel-collector:v0.144.13` | One-shot ClickHouse schema job, exits when done | — |
| `clickhouse` | `clickhouse/clickhouse-server:25.12.5` + config | Telemetry store (volume) | — |
| `clickhouse-keeper` | `clickhouse/clickhouse-keeper:25.12.5` + config | Coordination (volume) | — |

**First login.** Enter your email in `SIGNOZ_USER_ROOT_EMAIL` when deploying. After the stack is healthy (first boot takes a few minutes while the schema is created), open the `signoz` domain and sign in with that email and the generated `SIGNOZ_USER_ROOT_PASSWORD` from the service's Variables tab.

**Send telemetry from your Railway services.** Add to any service in the same project:

```
OTEL_EXPORTER_OTLP_ENDPOINT=http://${{otel-collector.RAILWAY_PRIVATE_DOMAIN}}:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_SERVICE_NAME=${{RAILWAY_SERVICE_NAME}}
```

and start the app with your language's OpenTelemetry auto-instrumentation. For gRPC use port `4317`. From outside Railway, use `https://{otel-collector domain}` and the header `Authorization=Bearer {OTLP_PUBLIC_TOKEN}`.

**Scaling.** The collector is stateless: raise its replica count when ingest grows. Give ClickHouse more memory/CPU for heavier queries, and set data retention in Settings → General to fit the ClickHouse volume.

**Pinning and upgrades.** All images are pinned. To upgrade, change the `signoz` and `schema-migrator` image tags and the collector's `FROM` tag together, then redeploy the migrator before the other services. Read the SigNoz release notes first.

### Why Deploy SigNoz on Railway?

Railway runs the whole observability stack next to the services it watches. Telemetry stays on the private network, volumes keep your data across deploys, and you pay for the resources the stack actually uses instead of per-host or per-seat APM pricing.
