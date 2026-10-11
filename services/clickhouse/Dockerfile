# ClickHouse telemetry store for SigNoz on Railway.
# Version matches the ClickHouse release SigNoz Foundry v0.3.0 generates for Docker installs.
FROM clickhouse/clickhouse-server:25.12.5

# histogramQuantile is an executable UDF that SigNoz queries depend on.
# It is published by SigNoz as a release asset; baked in at build time so
# it does not live on (and is not hidden by) the data volume.
ARG HISTOGRAM_QUANTILE_VERSION=v0.0.1

RUN set -eux; \
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"; \
    arch="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')"; \
    mkdir -p /etc/clickhouse-server/user_scripts; \
    wget -q -O /tmp/hq.tar.gz \
      "https://github.com/SigNoz/signoz/releases/download/histogram-quantile%2F${HISTOGRAM_QUANTILE_VERSION}/histogram-quantile_${os}_${arch}.tar.gz"; \
    tar -xzf /tmp/hq.tar.gz -C /tmp; \
    mv /tmp/histogram-quantile /etc/clickhouse-server/user_scripts/histogramQuantile; \
    chmod 0755 /etc/clickhouse-server/user_scripts/histogramQuantile; \
    rm -f /tmp/hq.tar.gz

# Overrides merged on top of the image's stock config.xml / users.xml.
COPY config.d/ /etc/clickhouse-server/config.d/
COPY users.d/ /etc/clickhouse-server/users.d/
# Matches the stock glob <user_defined_executable_functions_config>*_function.*ml
COPY histogram_quantile_function.xml /etc/clickhouse-server/histogram_quantile_function.xml
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 0755 /usr/local/bin/railway-entrypoint.sh

EXPOSE 8123 9000

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
