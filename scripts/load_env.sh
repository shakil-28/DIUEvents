#!/bin/bash
# Load .env file and export variables as DART_DEFINES for Flutter build
# Usage: source scripts/load_env.sh && flutter run

ENV_FILE="../.env"
if [ -f "$ENV_FILE" ]; then
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        key=$(echo "$key" | tr -d ' ')
        value=$(echo "$value" | tr -d ' ')
        dart_var=$(echo "$key" | tr '[:lower:]' '[:upper:]' | tr '_' '.')
        echo "Setting --dart-define ${dart_var}=${value}"
        DART_DEFINES+="--dart-define ${dart_var}=${value} "
    done < "$ENV_FILE"
    export DART_DEFINES
    echo "Loaded ${key:-0} environment variables"
else
    echo "Warning: .env file not found at $ENV_FILE"
    echo "Copy .env.example to .env and fill in your Firebase keys."
fi
