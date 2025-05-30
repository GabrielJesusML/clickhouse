###############################################################################
# ClickHouse with Environment Variable Support
###############################################################################
FROM clickhouse/clickhouse-server:24.8.5.115

# The official ClickHouse image supports CLICKHOUSE_LISTEN_HOST environment variable
# This is the simplest approach
ENV CLICKHOUSE_LISTEN_HOST=:: \
    CLICKHOUSE_DB=default \
    CLICKHOUSE_USER=admin \
    CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1 \
    CLICKHOUSE_PASSWORD=changeme

# Just to be extra sure, also create the config file
RUN mkdir -p /etc/clickhouse-server/config.d/ && \
    echo '<clickhouse><listen_host>::</listen_host><listen_host>0.0.0.0</listen_host></clickhouse>' \
    > /etc/clickhouse-server/config.d/listen.xml && \
    chown clickhouse:clickhouse /etc/clickhouse-server/config.d/listen.xml