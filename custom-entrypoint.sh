#!/bin/bash
set -e

echo "Starting ClickHouse custom initialization..."

# Function to replace placeholders in XML files
replace_env_vars() {
    local file=$1
    local temp_file="${file}.tmp"
    
    cp "$file" "$temp_file"
    
    # List of all environment variables to replace
    env_vars=(
        "CLICKHOUSE_USER"
        "CLICKHOUSE_PASSWORD"
        "CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT"
        "CLICKHOUSE_MAX_MEMORY_USAGE"
        "CLICKHOUSE_LOAD_BALANCING"
        "CLICKHOUSE_ALLOW_NONDETERMINISTIC_MUTATIONS"
        "CLICKHOUSE_PROFILE"
        "CLICKHOUSE_QUOTA"
        "CLICKHOUSE_HTTP_PORT"
        "CLICKHOUSE_TCP_PORT"
        "CLICKHOUSE_MYSQL_PORT"
        "CLICKHOUSE_POSTGRESQL_PORT"
        "CLICKHOUSE_INTERSERVER_HTTP_PORT"
        "CLICKHOUSE_MAX_CONNECTIONS"
        "CLICKHOUSE_MAX_CONCURRENT_QUERIES"
        "CLICKHOUSE_LOG_LEVEL"
        "CLICKHOUSE_PATH"
        "CLICKHOUSE_TMP_PATH"
        "CLICKHOUSE_UNCOMPRESSED_CACHE_SIZE"
        "CLICKHOUSE_MARK_CACHE_SIZE"
        "CLICKHOUSE_MMAP_CACHE_SIZE"
        "CLICKHOUSE_COMPILED_EXPRESSION_CACHE_SIZE"
        "CLICKHOUSE_KEEP_ALIVE_TIMEOUT"
        "CLICKHOUSE_MAX_OPEN_FILES"
        "CLICKHOUSE_MAX_TABLE_SIZE_TO_DROP"
        "CLICKHOUSE_MAX_PARTITION_SIZE_TO_DROP"
        "CLICKHOUSE_TIMEZONE"
        "CLICKHOUSE_MLOCK_EXECUTABLE"
        "CLICKHOUSE_DEFAULT_DATABASE"
        "CLICKHOUSE_MACRO_SHARD"
        "CLICKHOUSE_MACRO_REPLICA"
        "CLICKHOUSE_MACRO_CLUSTER"
        "CLICKHOUSE_ZOOKEEPER_HOSTS"
        "CLICKHOUSE_READONLY"
    )
    
    for var in "${env_vars[@]}"; do
        if [ ! -z "${!var}" ]; then
            echo "Replacing ${var} in ${file}"
            sed -i "s|{{${var}}}|${!var}|g" "$temp_file"
        fi
    done
    
    mv "$temp_file" "$file"
}

# Process template files if they exist
if [ -f "/etc/clickhouse-server/config.xml.template" ]; then
    echo "Processing config.xml template..."
    cp /etc/clickhouse-server/config.xml.template /etc/clickhouse-server/config.xml
    replace_env_vars /etc/clickhouse-server/config.xml
fi

if [ -f "/etc/clickhouse-server/users.xml.template" ]; then
    echo "Processing users.xml template..."
    cp /etc/clickhouse-server/users.xml.template /etc/clickhouse-server/users.xml
    replace_env_vars /etc/clickhouse-server/users.xml
fi

# Ensure listen-all.xml is in place
if [ -f "/etc/clickhouse-server/config.d/listen-all.xml.template" ]; then
    echo "Copying listen-all.xml template..."
    cp /etc/clickhouse-server/config.d/listen-all.xml.template /etc/clickhouse-server/config.d/listen-all.xml
    echo "listen-all.xml copied successfully"
    # Debug: show the content
    echo "Content of listen-all.xml:"
    cat /etc/clickhouse-server/config.d/listen-all.xml
fi

# Fix permissions
chown -R clickhouse:clickhouse /etc/clickhouse-server
chown -R clickhouse:clickhouse /var/lib/clickhouse
chown -R clickhouse:clickhouse /var/log/clickhouse-server

echo "Custom initialization completed. Starting official entrypoint..."

# Call the official entrypoint
exec /entrypoint.sh "$@"