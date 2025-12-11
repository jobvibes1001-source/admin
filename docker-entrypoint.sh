#!/bin/sh
set -e

# Get port from environment variable (Cloud Run sets this)
PORT=${PORT:-8080}

echo "Starting nginx on port ${PORT}..."

# Generate nginx configuration with dynamic port
# Using awk for port substitution (more reliable in Alpine)
cat > /tmp/nginx.conf.template <<'NGINX_EOF'
server {
    listen 0.0.0.0:__PORT__;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
NGINX_EOF

# Replace placeholder with actual port using awk (works in Alpine)
awk -v port="${PORT}" '{gsub(/__PORT__/, port); print}' /tmp/nginx.conf.template > /etc/nginx/conf.d/default.conf

# Verify the configuration file was created
if [ ! -f /etc/nginx/conf.d/default.conf ]; then
    echo "ERROR: Failed to create nginx configuration file"
    exit 1
fi

# Verify port was substituted
if grep -q "__PORT__" /etc/nginx/conf.d/default.conf; then
    echo "ERROR: Port placeholder was not replaced"
    exit 1
fi

echo "Nginx configuration created successfully"
echo "Testing nginx configuration..."

# Test nginx configuration
if ! nginx -t; then
    echo "ERROR: Nginx configuration test failed"
    cat /etc/nginx/conf.d/default.conf
    exit 1
fi

echo "Nginx configuration is valid"
echo "Starting nginx on 0.0.0.0:${PORT}..."

# Start nginx in foreground
exec nginx -g "daemon off;"

