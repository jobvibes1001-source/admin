#!/bin/sh
set -e

# Get port from environment variable (Cloud Run sets this)
PORT=${PORT:-8080}

echo "Starting nginx on port ${PORT}..."

# Remove any existing default config
rm -f /etc/nginx/conf.d/default.conf

# Generate nginx configuration with dynamic port
# Using a quoted heredoc to preserve nginx variables, then substitute PORT
cat > /etc/nginx/conf.d/default.conf <<'NGINX_TEMPLATE'
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
NGINX_TEMPLATE

# Replace PORT placeholder (using sed with backup extension for Alpine compatibility)
sed -i.bak "s/__PORT__/${PORT}/g" /etc/nginx/conf.d/default.conf
rm -f /etc/nginx/conf.d/default.conf.bak

echo "Nginx configuration created:"
cat /etc/nginx/conf.d/default.conf

echo "Testing nginx configuration..."
nginx -t

echo "Starting nginx on port ${PORT}..."
exec nginx -g "daemon off;"

