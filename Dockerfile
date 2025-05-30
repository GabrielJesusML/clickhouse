###############################################################################
# ClickHouse with Environment Variable Support
###############################################################################
FROM clickhouse/clickhouse-server:24.8.5.115

# Environment variables
ENV CLICKHOUSE_LISTEN_HOST=:: \
    CLICKHOUSE_DB=default \
    CLICKHOUSE_USER=admin \
    CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1 \
    CLICKHOUSE_PASSWORD=changeme

# Create config to disable NUMA and listen on all interfaces
RUN mkdir -p /etc/clickhouse-server/config.d/ && \
    echo '<?xml version="1.0"?>\n\
<clickhouse>\n\
    <!-- Listen on all interfaces -->\n\
    <listen_host>::</listen_host>\n\
    <listen_host>0.0.0.0</listen_host>\n\
    <!-- Disable NUMA optimization to avoid permission errors -->\n\
    <interserver_use_numa_aware_scheduling>0</interserver_use_numa_aware_scheduling>\n\
    <use_numa_aware_scheduling>0</use_numa_aware_scheduling>\n\
</clickhouse>' > /etc/clickhouse-server/config.d/docker-settings.xml && \
    chown clickhouse:clickhouse /etc/clickhouse-server/config.d/docker-settings.xml

# Create users configuration to ensure admin user is created properly
RUN mkdir -p /etc/clickhouse-server/users.d/ && \
    echo '<?xml version="1.0"?>\n\
<clickhouse>\n\
    <users>\n\
        <admin>\n\
            <password from_env="CLICKHOUSE_PASSWORD" />\n\
            <networks>\n\
                <ip>::/0</ip>\n\
            </networks>\n\
            <profile>default</profile>\n\
            <quota>default</quota>\n\
            <access_management from_env="CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT" />\n\
        </admin>\n\
    </users>\n\
</clickhouse>' > /etc/clickhouse-server/users.d/admin-user.xml && \
    chown clickhouse:clickhouse /etc/clickhouse-server/users.d/admin-user.xml

# Add startup script to suppress NUMA warnings
RUN echo '#!/bin/bash\n\
# Suppress NUMA warnings by redirecting stderr for get_mempolicy\n\
export CLICKHOUSE_WATCHDOG_ENABLE=0\n\
exec "$@" 2>&1 | grep -v "get_mempolicy: Operation not permitted" >&2' > /suppress-numa.sh && \
    chmod +x /suppress-numa.sh

# The official entrypoint will handle user creation based on env vars
ENTRYPOINT ["/suppress-numa.sh", "/entrypoint.sh"]