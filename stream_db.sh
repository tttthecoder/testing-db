#!/bin/bash

# =============================================================================
# Database Streaming Script
# =============================================================================
#
# This script streams data from a source PostgreSQL database to a target database,
# with the following features:
#
# 1. Ignores constraints (FK, unique, etc.) during import
# 2. Creates necessary schemas automatically
# 3. Handles both schema and data transfer
# 4. Cleans up temporary files automatically
#
# Usage:
#   1. Edit the database connection details below (SOURCE_* and TARGET_* variables)
#   2. Edit the TABLES array to include tables you want to stream
#   3. Run the script: ./stream_db.sh
#
# Table Format:
#   - Must be in format: "schema.table_name"
#   - Example: "public.users", "cdp.events"
#   - Tables must exist in the source database
#
# Requirements:
#   - PostgreSQL client tools (pg_dump, psql)
#   - Access to both source and target databases

set -euo pipefail
#=====================CONFIG START=================================
# Source database connection details
SOURCE_DB="momoshub"
SOURCE_USER="tin"
SOURCE_PASS="tintran@1"
SOURCE_HOST="momos-aurora.chshugawmpm5.ap-southeast-1.rds.amazonaws.com"

# Target database connection details
TARGET_DB="postgres"
TARGET_USER="tin"
TARGET_PASS="tin"
TARGET_HOST="localhost"

# List of tables to stream (must be in format: schema.table)
TABLES=(
    "public.accounts_data"
    "cdp.customer_events"
    "public.event_stream"      # Added public schema prefix
    "public.brands"
    "public.outbound_campaigns"
    "public.outbound_campaigns_send"
    "public.node_execution"    # Added public schema prefix
    "public.workflow_schedule" # Added public schema prefix
    "public.workflow_execution" # Added public schema prefix
    "public.processed_event_workflow" # Added public schema prefix
    "public.node_event_wait"   # Added public schema prefix
    "outlets"  # can ignore public schema prefix
)
#=====================CONFIG END=================================
echo "🚀 Starting database streaming process..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
for cmd in pg_dump psql; do
    if ! command_exists "$cmd"; then
        echo "❌ Error: $cmd is required but not installed."
        exit 1
    fi
done

# Create a temporary directory for the dump files
TEMP_DIR=$(mktemp -d)
echo "📁 Created temporary directory: $TEMP_DIR"

# Function to handle cleanup
cleanup() {
    echo "🧹 Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Export PGPASSWORD for source DB
export PGPASSWORD="$SOURCE_PASS"

echo "📤 Dumping schema from source database..."
SCHEMA_DUMP_ARGS=()
for table in "${TABLES[@]}"; do
    SCHEMA_DUMP_ARGS+=(--table="$table")
done

pg_dump -h "$SOURCE_HOST" -U "$SOURCE_USER" -d "$SOURCE_DB" \
    --schema-only \
    "${SCHEMA_DUMP_ARGS[@]}" \
    > "$TEMP_DIR/schema.sql"

# Dump data for each table
for table in "${TABLES[@]}"; do
    safe_name=$(echo "$table" | tr '.' '_')
    echo "📤 Dumping data for table: $table"
        pg_dump -h "$SOURCE_HOST" -U "$SOURCE_USER" -d "$SOURCE_DB" \
            --data-only \
            --table="$table" \
            --inserts \
            --disable-triggers \
            --no-owner \
            --no-acl \
            > "$TEMP_DIR/${safe_name}_data.sql"
done

# Export PGPASSWORD for target DB
export PGPASSWORD="$TARGET_PASS"

echo "📥 Extract unique schemas from table names and create them..."
for table in "${TABLES[@]}"; do
    schema=$(echo "$table" | cut -d'.' -f1)
    if [ "$schema" != "public" ]; then
        echo "Creating schema: $schema"
        psql -h "$TARGET_HOST" -U "$TARGET_USER" -d "$TARGET_DB" -c "CREATE SCHEMA IF NOT EXISTS $schema;"
    fi
done

echo "📥 Importing source schema(tables) into target database..."
psql -h "$TARGET_HOST" -U "$TARGET_USER" -d "$TARGET_DB" -c "SET session_replication_role = 'replica';" -f "$TEMP_DIR/schema.sql"

echo "📥 Import data for each table"
for table in "${TABLES[@]}"; do
    safe_name=$(echo "$table" | tr '.' '_')
    echo "📥 Importing data for table: $table"
    psql -h "$TARGET_HOST" -U "$TARGET_USER" -d "$TARGET_DB" -c "SET session_replication_role = 'replica';" -f "$TEMP_DIR/${safe_name}_data.sql"
done

# Reset session_replication_role back to default
psql -h "$TARGET_HOST" -U "$TARGET_USER" -d "$TARGET_DB" -c "SET session_replication_role = 'origin';"

echo "✅ Database streaming completed successfully!"

# Clean up sensitive env vars
unset PGPASSWORD
