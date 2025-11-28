#!/bin/sh
set -e

echo "=== LibreChat HF Spaces Startup ==="

# Create directories with proper permissions
mkdir -p /app/logs /app/uploads /app/images 2>/dev/null || true

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

# Check required environment variables
if [ -z "$MONGO_URI" ]; then
    echo "ERROR: MONGO_URI not set!"
    echo "Please add your MongoDB Atlas connection string to HF Spaces secrets."
    echo "Get a free MongoDB Atlas cluster at: https://www.mongodb.com/atlas/database"
    echo ""
    echo "Example: MONGO_URI=mongodb+srv://user:password@cluster.mongodb.net/LibreChat"
    exit 1
fi

if [ -z "$HUGGINGFACE_TOKEN" ]; then
    echo "WARNING: HUGGINGFACE_TOKEN not set!"
    echo "Add it to HF Spaces secrets for the HF Inference API endpoints to work."
    echo "Get your token at: https://huggingface.co/settings/tokens"
fi

echo "MongoDB URI configured: $(echo $MONGO_URI | sed 's/:.*@/:***@/')"
echo "Starting LibreChat on port ${PORT:-7860}..."

# Start the application
exec npm run backend
