# SigNoz OpenTelemetry Collector with a Railway-specific ingest config.
FROM signoz/signoz-otel-collector:v0.144.13

USER root
COPY config.yaml /etc/signoz/collector.yaml
COPY entrypoint.sh /usr/local/bin/railway-collector-entrypoint.sh
RUN chmod 0644 /etc/signoz/collector.yaml \
 && chmod 0755 /usr/local/bin/railway-collector-entrypoint.sh
# Same non-root UID as the upstream image.
USER 10001

# 4317/4318: private OTLP, 14317/14318: public OTLP (token), 13133: health
EXPOSE 4317 4318 14317 14318 13133

ENTRYPOINT ["/usr/local/bin/railway-collector-entrypoint.sh"]
