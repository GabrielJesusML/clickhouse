###############################################################################
# ClickHouse with Environment Variable Support
###############################################################################
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG apt_archive="http://archive.ubuntu.com"

# Create user and install base dependencies
RUN sed -i "s|http://archive.ubuntu.com|${apt_archive}|g" /etc/apt/sources.list \
 && groupadd -r clickhouse --gid=101 \
 && useradd -r -g clickhouse --uid=101 --home-dir=/var/lib/clickhouse --shell=/bin/bash clickhouse \
 && apt-get update \
 && apt-get install --yes --no-install-recommends \
    ca-certificates \
    locales \
    tzdata \
    wget \
    curl \
    gnupg \
 && rm -rf /var/lib/apt/lists/* /var/cache/debconf /tmp/*

# Install ClickHouse
ARG REPO_CHANNEL="stable"
ARG REPOSITORY="deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb ${REPO_CHANNEL} main"
ARG VERSION="24.8.5.115"
ARG PACKAGES="clickhouse-client clickhouse-server clickhouse-common-static"

# Download and install ClickHouse GPG key using curl
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
    apt-transport-https \
    dirmngr \
 && mkdir -p /usr/share/keyrings \
 && curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | \
    gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg \
 && chmod 644 /usr/share/keyrings/clickhouse-keyring.gpg \
 && echo "${REPOSITORY}" > /etc/apt/sources.list.d/clickhouse.list \
 && apt-get update \
 && apt-get install --yes --no-install-recommends ${PACKAGES} \
 && rm -rf /var/lib/apt/lists/* /var/cache/debconf /tmp/*

# Post-install setup
RUN clickhouse-local -q 'SELECT * FROM system.build_options' \
 && mkdir -p \
    /var/lib/clickhouse \
    /var/log/clickhouse-server \
    /etc/clickhouse-server/config.d \
    /etc/clickhouse-server/users.d \
    /etc/clickhouse-client \
    /docker-entrypoint-initdb.d \
 && chmod ugo+Xrw -R \
    /var/lib/clickhouse \
    /var/log/clickhouse-server \
    /etc/clickhouse-server \
    /etc/clickhouse-client

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV TZ=UTC

# Copy configuration templates
COPY config.xml.template /etc/clickhouse-server/config.xml.template
COPY users.xml.template /etc/clickhouse-server/users.xml.template
COPY listen-all.xml.template /etc/clickhouse-server/config.d/listen-all.xml.template

# Copy custom entrypoint
COPY custom-entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh

# Download official entrypoint
ADD https://raw.githubusercontent.com/ClickHouse/ClickHouse/master/docker/server/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
EXPOSE 8123 9000 9009

# Volume for data persistence
VOLUME /var/lib/clickhouse

# Default environment variables
ENV CLICKHOUSE_USER=admin \
    CLICKHOUSE_PASSWORD=changeme \
    CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1 \
    CLICKHOUSE_MAX_MEMORY_USAGE=10000000000 \
    CLICKHOUSE_LOAD_BALANCING=random \
    CLICKHOUSE_ALLOW_NONDETERMINISTIC_MUTATIONS=1 \
    CLICKHOUSE_PROFILE=default \
    CLICKHOUSE_QUOTA=default \
    CLICKHOUSE_HTTP_PORT=8123 \
    CLICKHOUSE_TCP_PORT=9000 \
    CLICKHOUSE_MYSQL_PORT=9004 \
    CLICKHOUSE_POSTGRESQL_PORT=9005 \
    CLICKHOUSE_INTERSERVER_HTTP_PORT=9009 \
    CLICKHOUSE_MAX_CONNECTIONS=4096 \
    CLICKHOUSE_MAX_CONCURRENT_QUERIES=100 \
    CLICKHOUSE_LOG_LEVEL=information \
    CLICKHOUSE_PATH=/var/lib/clickhouse/ \
    CLICKHOUSE_TMP_PATH=/var/lib/clickhouse/tmp/ \
    CLICKHOUSE_UNCOMPRESSED_CACHE_SIZE=8589934592 \
    CLICKHOUSE_MARK_CACHE_SIZE=5368709120 \
    CLICKHOUSE_MMAP_CACHE_SIZE=1000 \
    CLICKHOUSE_COMPILED_EXPRESSION_CACHE_SIZE=134217728 \
    CLICKHOUSE_KEEP_ALIVE_TIMEOUT=3 \
    CLICKHOUSE_TIMEZONE=UTC \
    CLICKHOUSE_MLOCK_EXECUTABLE=true \
    CLICKHOUSE_DEFAULT_DATABASE=default \
    CLICKHOUSE_MAX_TABLE_SIZE_TO_DROP=0 \
    CLICKHOUSE_MAX_PARTITION_SIZE_TO_DROP=0 \
    CLICKHOUSE_MACRO_SHARD=01 \
    CLICKHOUSE_MACRO_REPLICA=replica01 \
    CLICKHOUSE_MACRO_CLUSTER=cluster01 \
    CLICKHOUSE_READONLY=0 \
    CLICKHOUSE_CONFIG=/etc/clickhouse-server/config.xml

# Use custom entrypoint
ENTRYPOINT ["/custom-entrypoint.sh"]
CMD ["clickhouse", "server"]