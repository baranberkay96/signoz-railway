# ClickHouse Keeper (coordination for SigNoz's replicated tables / ON CLUSTER DDL).
FROM clickhouse/clickhouse-keeper:25.12.5

COPY keeper.xml /etc/clickhouse-keeper/keeper.xml

# Read by the official entrypoint: config file to use, and the data directory
# whose coordination/{log,snapshots} folders it creates and chowns on the volume.
ENV KEEPER_CONFIG=/etc/clickhouse-keeper/keeper.xml \
    CLICKHOUSE_DATA_DIR=/var/lib/clickhouse-keeper

EXPOSE 9181 9182
