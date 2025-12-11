#!/bin/sh
set -e

# Get port from environment variable (Cloud Run sets this)
export PORT=${PORT:-8080}

echo "Starting nginx on port ${PORT}..."

# Verify files exist
if [ ! -f /usr/share/nginx/html/index.html ]; then
    echo "ERROR: index.html not found"
    exit 1
fi

# Use envsubst to substitute PORT in nginx.conf template
# Copy template and substitute environment variables
envsubst '$PORT' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

echo "Nginx configuration:"
cat /etc/nginx/conf.d/default.conf

# Test configuration
nginx -t

# Start nginx
exec nginx -g "daemon off;"

