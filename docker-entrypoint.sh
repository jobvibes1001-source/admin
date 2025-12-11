#!/bin/sh
set -e

# Get port from environment variable (Cloud Run sets this)
PORT=${PORT:-8080}

# Generate nginx configuration with dynamic port
cat > /etc/nginx/conf.d/default.conf <<'NGINX_EOF'
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

# Replace placeholder with actual port
sed -i "s/__PORT__/${PORT}/g" /etc/nginx/conf.d/default.conf

# Test nginx configuration
nginx -t

# Start nginx in foreground
exec nginx -g "daemon off;"

