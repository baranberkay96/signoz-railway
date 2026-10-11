# NOTICE — SigNoz template

This is a community template. It is not affiliated with or endorsed by SigNoz Inc. or ClickHouse Inc.

## Upstream sources checked (2026-10-10)

| Source | Version / path | License | Use |
|---|---|---|---|
| SigNoz/signoz | tag `v0.145.0`: `conf/example.yaml`, `pkg/config/envprovider`, `pkg/types/factor_password.go`, `deploy/README.md`, `deploy/MIGRATION.md` | MIT (outside `ee/`) | Env-var names, password rules, deprecation of `deploy/` compose |
| SigNoz/signoz | tag `v0.129.0`: `deploy/docker/docker-compose.yaml`, `deploy/common/clickhouse/{custom-function.xml,cluster.xml,config.xml}` (last tags that ship Compose files) | MIT | Topology; `histogram_quantile_function.xml` follows the structure of `custom-function.xml` |
| SigNoz/signoz | `ee/LICENSE`, `ee/sqlstore/postgressqlstore` | SigNoz Enterprise License | Read only, to decide the metastore default (SQLite) |
| SigNoz/foundry | tag `v0.3.0`: `docs/examples/docker/compose/pours/deployment/*`, `docs/examples/railway/template/*` | AGPL-3.0 | Reference only for current defaults (image versions, collector pipeline, Keeper settings). No files copied; configs here were written for this template |
| SigNoz/signoz-otel-collector | tag `v0.144.13`: `components/components.go`, `cmd/signozotelcollector/*`, `extension/healthcheckextension` | AGPL-3.0 | Available extensions (bearertokenauth), migrate flags, health endpoint |
| ClickHouse/ClickHouse | tag `v25.12.5.44-stable`: `docker/server/entrypoint.sh`, `docker/keeper/entrypoint.sh`, `programs/server/config.xml` | Apache-2.0 | Entrypoint behaviour (`CLICKHOUSE_PASSWORD`, `KEEPER_CONFIG`), stock config to override |
| ClickHouse docs | Keeper guide (`http_control` readiness) | — | Keeper readiness syntax |

## Market templates and repos reviewed

| Code / repo | License | Use |
|---|---|---|
| `signoz-1` → github.com/gridalpha/signoz-railway | none (all rights reserved) | Ideas only (service split, authenticated ingest). No files or text copied. |
| `signoz` → github.com/SigNoz/signoz-railway-template | no license file | Ideas only (vendor's Railway layout uses SQLite metastore). No files or text copied. |
| `signoz-observability` (inline start commands) | n/a | Reviewed, not used |

## Third-party binaries fetched at build time

- `histogram-quantile` v0.0.1 — release asset of SigNoz/signoz (`histogram-quantile/v0.0.1`), MIT, downloaded in `services/clickhouse/Dockerfile`.

## Images used at runtime (unmodified, pulled from Docker Hub)

- `signoz/signoz:v0.145.0` — SigNoz's standard self-host image. It contains code under MIT and, in `ee/`, under the SigNoz Enterprise License; features gated by that licence stay disabled without a SigNoz licence key.
- `signoz/signoz-otel-collector:v0.144.13` — AGPL-3.0. Used unmodified; the `otel-collector` image only adds a config file and a start script on top of it.
- `clickhouse/clickhouse-server:25.12.5`, `clickhouse/clickhouse-keeper:25.12.5` — Apache-2.0.

All files in `template/` (configs, entrypoints, Dockerfiles, documentation) were written for this template.
