#!/bin/sh
set -e

echo "=== LibreChat HF Spaces Startup ==="

# Create directories with proper permissions
mkdir -p /app/logs /app/uploads /app/images /data/db 2>/dev/null || true
chown -R 1000:1000 /data/db 2>/dev/null || true

# Start MongoDB in background
# Note: --noauth is used because this is an embedded instance only accessible via localhost
# External access is not possible in the HF Spaces container environment
echo "Starting embedded MongoDB..."
mongod --dbpath /data/db --bind_ip 127.0.0.1 --port 27017 --fork --logpath /app/logs/mongodb.log --noauth

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to start..."
MONGO_READY=0
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    if mongosh --eval "db.adminCommand('ping')" --quiet 2>/dev/null; then
        echo "MongoDB is ready!"
        MONGO_READY=1
        break
    fi
    echo "Waiting... ($i/15)"
    sleep 2
done

if [ "$MONGO_READY" != "1" ]; then
    echo "ERROR: MongoDB failed to start within 30 seconds!"
    echo "Check /app/logs/mongodb.log for details"
    cat /app/logs/mongodb.log 2>/dev/null || true
    exit 1
fi

# Generate random secrets if not provided
if [ -z "$JWT_SECRET" ]; then
    export JWT_SECRET=$(head -c 32 /dev/urandom | xxd -p 2>/dev/null || head -c 100 /dev/urandom | tr -dc 'a-f0-9' | head -c 64)
    echo "Generated JWT_SECRET"
fi

if [ -z "$JWT_REFRESH_SECRET" ]; then
    export JWT_REFRESH_SECRET=$(head -c 32 /dev/urandom | xxd -p 2>/dev/null || head -c 100 /dev/urandom | tr -dc 'a-f0-9' | head -c 64)
    echo "Generated JWT_REFRESH_SECRET"
fi

if [ -z "$CREDS_KEY" ]; then
    export CREDS_KEY=$(head -c 32 /dev/urandom | xxd -p 2>/dev/null || head -c 100 /dev/urandom | tr -dc 'a-f0-9' | head -c 64)
    echo "Generated CREDS_KEY"
fi

if [ -z "$CREDS_IV" ]; then
    export CREDS_IV=$(head -c 16 /dev/urandom | xxd -p 2>/dev/null || head -c 50 /dev/urandom | tr -dc 'a-f0-9' | head -c 32)
    echo "Generated CREDS_IV"
fi

# Set MongoDB URI to embedded instance
export MONGO_URI="mongodb://127.0.0.1:27017/LibreChat"

# Check if HUGGINGFACE_TOKEN is set
if [ -z "$HUGGINGFACE_TOKEN" ]; then
    echo "WARNING: HUGGINGFACE_TOKEN not set!"
    echo "Add it to HF Spaces secrets for the HF Inference API endpoints to work."
    echo "Get your token at: https://huggingface.co/settings/tokens"
fi

echo "MongoDB running on localhost:27017"
echo "Starting LibreChat on port ${PORT:-7860}..."

# Start the application (runs as current user)
exec npm run backend
