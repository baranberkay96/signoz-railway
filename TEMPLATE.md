# SigNoz v0.145 APM for Railway Apps — composer spec

| Field | Value |
|---|---|
| Listing name | **SigNoz v0.145 APM for Railway Apps** (version label `v0.145` = SigNoz 0.x major.minor) |
| Description | Logs, traces and metrics in one place. OpenTelemetry-native Datadog alternative. (80 chars, unchanged from LISTINGS.md) |
| Category | Observability |
| Tags | observability, apm, opentelemetry, tracing, logs, metrics, clickhouse |
| Base market template | `signoz-1` (gridalpha, 5 services + Postgres, authenticated ingest) — structure only; source repo has no license, nothing copied. Also reviewed `signoz` (vendor, 175 projects) and `signoz-observability`. |
| Upstream checked | SigNoz `v0.145.0` (2026-10-05), SigNoz OTel Collector `v0.144.13` (2026-10-08), SigNoz Foundry `v0.3.0` Docker Compose example (ClickHouse/Keeper `25.12.5`). Images pinned 2026-10-10. |

## Architecture

```
 your Railway services ──(private, no auth)──► otel-collector :4317 gRPC / :4318 HTTP
 external apps ──(HTTPS domain, Bearer token)──► otel-collector :14318  (public domain)
 external apps ──(TCP proxy, Bearer token)─────► otel-collector :14317  (gRPC)
                                                     │  OpAMP ws :4320 ◄── signoz
                                                     ▼
 schema-migrator (one-shot) ───────────────► clickhouse :9000 ◄── signoz (UI/API :8080, public)
                                                     │
                                                     ▼
                                          clickhouse-keeper :9181
```

## Services

| Service | Source | Start command | Public networking | Healthcheck | Volume | Restart |
|---|---|---|---|---|---|---|
| `clickhouse` | repo `services/clickhouse` (FROM `clickhouse/clickhouse-server:25.12.5`) | image entrypoint (wrapper) | none (private :9000/:8123) | `/ping` on PORT=8123, 300 s | `/var/lib/clickhouse` | ON_FAILURE ×10 |
| `clickhouse-keeper` | repo `services/clickhouse-keeper` (FROM `clickhouse/clickhouse-keeper:25.12.5`) | image entrypoint | none (private :9181) | `/ready` on PORT=9182, 300 s | `/var/lib/clickhouse-keeper` | ON_FAILURE ×10 |
| `schema-migrator` | image `signoz/signoz-otel-collector:v0.144.13` | `/bin/sh -c '/signoz-otel-collector migrate ready && … bootstrap && … sync up && … async up'` | none | none (one-shot job, exits 0) | none | ON_FAILURE ×10 |
| `signoz` | image `signoz/signoz:v0.145.0` | image default (`./signoz server`) | domain → 8080 | `/api/v1/health` on PORT=8080, 300 s | `/var/lib/signoz` (SQLite metastore) | ON_FAILURE ×10 |
| `otel-collector` | repo `services/otel-collector` (FROM `signoz/signoz-otel-collector:v0.144.13`) | custom entrypoint (waits for schema) | domain → 14318 (OTLP/HTTP), TCP proxy → 14317 (OTLP/gRPC) | `/` on PORT=13133, 600 s | none (stateless) | ON_FAILURE ×10 |

Service names matter: they become the private hostnames (`clickhouse.railway.internal`, …) and are used in reference variables. Keep them lower-case as listed.

## Variables

### clickhouse
| Variable | Default | Notes |
|---|---|---|
| `PORT` | `8123` | Healthcheck port. |
| `CLICKHOUSE_PASSWORD` | `${{secret(32, "a–zA–Z0–9")}}` | Official entrypoint recreates user `default` with this password and `::/0` network access. |
| `CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT` | `1` | SQL-driven user management for `default`. |
| `CLICKHOUSE_KEEPER_HOST` | `${{clickhouse-keeper.RAILWAY_PRIVATE_DOMAIN}}` | Injected into `<zookeeper>` via `from_env`. |
| `CLICKHOUSE_DSN` | `tcp://default:${{CLICKHOUSE_PASSWORD}}@${{RAILWAY_PRIVATE_DOMAIN}}:9000` | Referenced by every SigNoz component. |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `60` | Clean shutdown. |

### clickhouse-keeper
| Variable | Default | Notes |
|---|---|---|
| `PORT` | `9182` | Keeper HTTP control (readiness). |

### schema-migrator
| Variable | Default | Notes |
|---|---|---|
| `SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_DSN` | `${{clickhouse.CLICKHOUSE_DSN}}` | |
| `SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_CLUSTER` | `cluster` | Must match `remote_servers` in `config.d/signoz.xml`. |
| `SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_REPLICATION` | `true` | Upstream default (Replicated tables via Keeper). |
| `SIGNOZ_OTEL_COLLECTOR_TIMEOUT` | `10m` | `migrate ready` keeps retrying while ClickHouse boots. |

### signoz
| Variable | Default | Notes |
|---|---|---|
| `PORT` | `8080` | |
| `SIGNOZ_TELEMETRYSTORE_PROVIDER` | `clickhouse` | |
| `SIGNOZ_TELEMETRYSTORE_CLICKHOUSE_DSN` | `${{clickhouse.CLICKHOUSE_DSN}}` | |
| `SIGNOZ_TELEMETRYSTORE_CLICKHOUSE_CLUSTER` | `cluster` | |
| `SIGNOZ_SQLSTORE_PROVIDER` | `sqlite` | See "Metadata store" below. |
| `SIGNOZ_SQLSTORE_SQLITE_PATH` | `/var/lib/signoz/signoz.db` | On the volume. |
| `SIGNOZ_TOKENIZER_JWT_SECRET` | `${{secret(64)}}` | |
| `SIGNOZ_USER_ROOT_ENABLED` | `true` | Admin is provisioned at boot → no open sign-up window. |
| `SIGNOZ_USER_ROOT_EMAIL` | *(empty)* | **Required input.** |
| `SIGNOZ_USER_ROOT_PASSWORD` | `${{secret(24, …)}}-Aa1` | Suffix guarantees SigNoz's rule (≥12 chars, upper, lower, digit, symbol). |
| `SIGNOZ_USER_ROOT_ORG_NAME` | `default` | |
| `SIGNOZ_GLOBAL_EXTERNAL__URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | `__` = literal underscore in SigNoz env mapping. |
| `SIGNOZ_GLOBAL_INGESTION__URL` | `https://${{otel-collector.RAILWAY_PUBLIC_DOMAIN}}` | Shown in onboarding. |
| `SIGNOZ_ALERTMANAGER_SIGNOZ_EXTERNAL__URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Links in alert notifications. |
| `SIGNOZ_STATSREPORTER_ENABLED` | `true` | Upstream default; set `false` to opt out of usage stats. |

Optional (add only when needed): SMTP for invites/alerts — `SIGNOZ_EMAILING_ENABLED=true`, `SIGNOZ_EMAILING_SMTP_ADDRESS=host:587`, `SIGNOZ_EMAILING_SMTP_FROM`, `SIGNOZ_EMAILING_SMTP_AUTH_USERNAME`, `SIGNOZ_EMAILING_SMTP_AUTH_PASSWORD`. Railway allows outbound SMTP only on the Pro plan; on Hobby use Slack, webhook or PagerDuty alert channels.

### otel-collector
| Variable | Default | Notes |
|---|---|---|
| `PORT` | `13133` | Health endpoint (separate from OTLP ports). |
| `CLICKHOUSE_DSN` | `${{clickhouse.CLICKHOUSE_DSN}}` | Used by all exporters via `${env:CLICKHOUSE_DSN}`. |
| `SIGNOZ_HOST` | `${{signoz.RAILWAY_PRIVATE_DOMAIN}}` | OpAMP target (`ws://<host>:4320/v1/opamp`). |
| `SIGNOZ_OTEL_COLLECTOR_TIMEOUT` | `10m` | `migrate sync check` wait at boot. |
| `OTLP_PUBLIC_TOKEN` | `${{secret(48, "a–zA–Z0–9")}}` | Bearer token for the public listeners only. |
| `LOW_CARDINAL_EXCEPTION_GROUPING` | `false` | Upstream default. |

## Composer steps (Railway dashboard)

1. Create the five services with the exact names above. For `clickhouse`, `clickhouse-keeper`, `otel-collector` choose *GitHub repo* → `baranberkay96/signoz-railway`, root directory `/services/<name>` (Dockerfile builder is auto-detected). For `signoz` and `schema-migrator` choose *Docker image* with the pinned tags.
2. Attach volumes: `clickhouse` → `/var/lib/clickhouse`, `clickhouse-keeper` → `/var/lib/clickhouse-keeper`, `signoz` → `/var/lib/signoz`.
3. Paste the variables per service (tables above).
4. Networking: `signoz` → generate domain, target port 8080. `otel-collector` → generate domain, target port **14318**; add TCP proxy on application port **14317**.
5. Deploy settings: healthcheck paths/timeouts and restart policies as in the services table; `schema-migrator` start command as listed.
6. Mark `SIGNOZ_USER_ROOT_EMAIL` as a required template input.

## Sending telemetry from other Railway services (private network)

Add to any service in the same project/environment (no token needed on the private listeners):

```
OTEL_EXPORTER_OTLP_ENDPOINT=http://${{otel-collector.RAILWAY_PRIVATE_DOMAIN}}:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_SERVICE_NAME=${{RAILWAY_SERVICE_NAME}}
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=${{RAILWAY_ENVIRONMENT_NAME}}
```

gRPC instead: `OTEL_EXPORTER_OTLP_ENDPOINT=http://${{otel-collector.RAILWAY_PRIVATE_DOMAIN}}:4317`, `OTEL_EXPORTER_OTLP_PROTOCOL=grpc`.
Then run the app with the language's OpenTelemetry auto-instrumentation (e.g. `node --require @opentelemetry/auto-instrumentations-node/register`, `opentelemetry-instrument python app.py`, the Java agent `-javaagent:opentelemetry-javaagent.jar`). Logs reach SigNoz when the app exports them via an OTel logs SDK/bridge; Railway's own platform log stream is not forwarded automatically.

From outside Railway (or another project): `OTEL_EXPORTER_OTLP_ENDPOINT=https://<otel-collector public domain>`, `OTEL_EXPORTER_OTLP_HEADERS=Authorization=Bearer <OTLP_PUBLIC_TOKEN>`. The TCP proxy (gRPC) is plain TCP without TLS — prefer the HTTPS domain on the public internet.

## Metadata store

SigNoz needs a SQL "metastore" for users, dashboards and alert rules. This template uses **SQLite on the `signoz` volume**, which is what the vendor's own Railway layout (Foundry `platform: railway`) generates. Foundry's Docker Compose default is Postgres; in SigNoz v0.145.0 the Postgres store is implemented under `ee/` (SigNoz Enterprise License, production use tied to a SigNoz subscription), so it is not enabled by default here. To switch after confirming licensing with SigNoz: add the Railway Postgres service, set `SIGNOZ_SQLSTORE_PROVIDER=postgres` and `SIGNOZ_SQLSTORE_POSTGRES_DSN=${{Postgres.DATABASE_URL}}` (fresh install; there is no automatic SQLite→Postgres migration).

## Improvements over market templates

| Area | Market templates | This template |
|---|---|---|
| Version pinning | `signoz` (vendor) and `signoz-1` build from `:latest` | All images pinned (SigNoz v0.145.0, collector v0.144.13, ClickHouse/Keeper 25.12.5) |
| Coordination | `signoz-observability` uses deprecated `signoz/zookeeper:3.7.1` with anonymous login | ClickHouse Keeper 25.12.5, as current upstream (Foundry) does |
| Config delivery | `signoz-observability` downloads configs/binaries from GitHub on every boot via a 60-line start command | Configs and the histogramQuantile UDF baked into small images; boots offline |
| ClickHouse auth | vendor template: passwordless `default` user | Generated password via the official entrypoint; shared `CLICKHOUSE_DSN` reference |
| Ingest security | vendor: public OTLP without auth | Public listeners require a Bearer token; private-network listeners stay token-free for Railway services |
| Admin bootstrap | vendor: first visitor signs up as admin | Root user provisioned from variables (no open sign-up window) |
| Resource use | stock ClickHouse logs (text_log at trace level, metric_log…) grow the volume | Noisy system tables disabled, 3-day TTL on the rest, cache caps for predictable RAM |
| Logs | ClickHouse writes log files inside the container | Console logging only (visible in Railway logs) |
| Networking | IPv4-only binds in several services | OTLP and Keeper listen dual-stack (`::`), ClickHouse via image default |
| Docs | — | Copy-paste OTEL_* variables for other Railway services, public ingest instructions, licensing note on metastore |

## Resource profile and cost (Railway: RAM $10/GB-mo, vCPU $20/mo, volume $0.15/GB-mo)

| Service | Idle RAM | Typical RAM | Idle CPU | Typical CPU | Volume |
|---|---|---|---|---|---|
| clickhouse | 0.6 GB | 1.5–2.5 GB | 0.05 | 0.3–1.0 | 5–20 GB |
| clickhouse-keeper | 0.08 GB | 0.15 GB | 0.01 | 0.02 | < 0.5 GB |
| schema-migrator | 0 (exits) | 0 | 0 | 0 | — |
| signoz | 0.15 GB | 0.3–0.6 GB | 0.01 | 0.1 | < 0.5 GB |
| otel-collector | 0.1 GB | 0.2–0.6 GB | 0.01 | 0.1–0.3 | — |
| **Total** | **~0.95 GB** | **~2.5–3.8 GB** | **~0.08 vCPU** | **~0.5–1.4 vCPU** | **~6–21 GB** |

Estimated monthly cost: **idle ≈ $12** (0.95 GB × $10 + 0.08 × $20 + 6 GB × $0.15); **typical small team (a few services, 7-day retention) ≈ $40–50**; heavy ingest (6 GB RAM, 1.5 vCPU, 50 GB) ≈ $100.
Minimum plan: **Hobby** (ClickHouse alone can exceed Trial's 1 GB/service under query load; Hobby volume limit 5 GB/service → set SigNoz retention to ~3–7 days). **Pro** recommended for >5 GB of telemetry or longer retention.

## Pinning and upgrades

Tags pinned 2026-10-10: `signoz/signoz:v0.145.0`, `signoz/signoz-otel-collector:v0.144.13` (both images use it: migrator and collector must match), `clickhouse/clickhouse-server:25.12.5`, `clickhouse/clickhouse-keeper:25.12.5`. Upgrade by changing the tag on `signoz` + `schema-migrator` and the `FROM` line in `services/otel-collector/Dockerfile`, then redeploy `schema-migrator` first. Check the SigNoz release notes for required collector versions before bumping.

## Verification checklist

- [ ] `clickhouse-keeper` healthy (`/ready`), then `clickhouse` healthy (`/ping`).
- [ ] `schema-migrator` logs end with the async migrations and the container exits with code 0.
- [ ] `otel-collector` passes `migrate sync check`, becomes healthy on `/`.
- [ ] Open the `signoz` domain, log in with `SIGNOZ_USER_ROOT_EMAIL` / `SIGNOZ_USER_ROOT_PASSWORD`; no sign-up page is offered.
- [ ] Private ingest: from another service run `curl -s -X POST http://otel-collector.railway.internal:4318/v1/traces -H 'Content-Type: application/json' -d '{"resourceSpans":[]}'` → HTTP 200.
- [ ] Public ingest: same request against the public domain without header → 401; with `Authorization: Bearer $OTLP_PUBLIC_TOKEN` → 200.
- [ ] Instrument a sample service with the OTEL_* variables; it appears under Services within ~1 min; logs and traces correlate.
- [ ] Settings → Ingestion pipelines: create a log pipeline; collector logs show the OpAMP config update.
- [ ] Redeploy `clickhouse` and `signoz`: data, dashboards and users persist.
- [ ] Set retention (Settings → General) to fit the ClickHouse volume.

## Open questions

- Not deployed end-to-end here (local files only). The ClickHouse `from_env` Keeper host, the merged system-log overrides and the bearer-token auth on `otlp/public` are standard ClickHouse/OTel features but need a first-deploy check.
- SigNoz hardcodes the OpAMP listener to `0.0.0.0:4320` (IPv4). In legacy IPv6-only Railway environments the collector cannot reach OpAMP (ingestion still works; UI-managed log pipelines do not). New environments are dual-stack.
- Postgres metastore lives under SigNoz's `ee/` licence in v0.145.0 — kept off by default; confirm with SigNoz before enabling for production. `signoz/signoz-community` (MIT build, SQLite only) is an alternative image if a strictly open-source build is required.
- ClickHouse is pinned to the version SigNoz Foundry tests (25.12.5); newer 25.12.x patch tags exist (25.12.11) and could be adopted after testing.
