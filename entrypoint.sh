#!/bin/bash
set -e

FIRST_RUN_FLAG="/usr/share/logstash/data/.first_run_complete"
DATA_DIR="/usr/share/logstash/data"

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Function to remove schedule from pipeline configs
remove_schedule() {
    echo "Removing schedule for first run (will execute immediately)..."
    find /usr/share/logstash/pipelines -name "*.conf" -type f -exec sed -i '/schedule =>/d' {} \;
}

# Function to restore schedule from environment variable
restore_schedule() {
    echo "Restoring schedule: ${SCHEDULE}"
    find /usr/share/logstash/pipelines -name "*.conf" -type f | while read file; do
        # Check if schedule already exists
        if ! grep -q "schedule =>" "$file"; then
            # Insert schedule line after jdbc_driver_class line
            sed -i "/jdbc_driver_class/a\    schedule => \"${SCHEDULE}\"" "$file"
        fi
    done
}

# Check if this is the first run
if [ ! -f "$FIRST_RUN_FLAG" ]; then
    echo "First run detected - will execute immediately without schedule"
    remove_schedule
    
    # Start logstash in background for first run
    echo "Starting logstash for initial full load..."
    if [ -f /usr/local/bin/docker-entrypoint ]; then
        /usr/local/bin/docker-entrypoint logstash &
    else
        /usr/share/logstash/bin/logstash &
    fi
    LOGSTASH_PID=$!
    
    # Wait for logstash to complete initial load
    # JDBC input without schedule will run once and exit
    echo "Waiting for initial data processing..."
    wait $LOGSTASH_PID || true
    
    echo "Initial load completed. Restoring schedule for subsequent runs..."
    # Mark first run as complete
    touch "$FIRST_RUN_FLAG"
    # Restore schedule
    restore_schedule
    echo "Restarting logstash with schedule: ${SCHEDULE}"
    # Restart with schedule
    exec "$0"
fi

# Subsequent runs: start logstash with schedule
echo "Starting logstash with schedule: ${SCHEDULE}"
if [ -f /usr/local/bin/docker-entrypoint ]; then
    exec /usr/local/bin/docker-entrypoint logstash
else
    exec /usr/share/logstash/bin/logstash
fi
