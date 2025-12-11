#!/bin/sh

# Get port from environment variable (Cloud Run sets this)
PORT=${PORT:-8080}

echo "========================================="
echo "Starting nginx on port ${PORT}..."
echo "========================================="

# Verify files exist
if [ ! -d /usr/share/nginx/html ]; then
    echo "ERROR: /usr/share/nginx/html does not exist"
    exit 1
fi

if [ ! -f /usr/share/nginx/html/index.html ]; then
    echo "ERROR: index.html not found in /usr/share/nginx/html"
    ls -la /usr/share/nginx/html/
    exit 1
fi

echo "Content directory verified"

# Remove any existing default config
rm -f /etc/nginx/conf.d/default.conf

# Generate nginx configuration with dynamic port
echo "Generating nginx configuration for port ${PORT}..."
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen 0.0.0.0:${PORT};
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

echo "Nginx configuration created:"
cat /etc/nginx/conf.d/default.conf

# Verify port is in the config
if ! grep -q "listen.*${PORT}" /etc/nginx/conf.d/default.conf; then
    echo "ERROR: Port ${PORT} not found in nginx configuration!"
    exit 1
fi

echo "Testing nginx configuration..."
if ! nginx -t; then
    echo "ERROR: Nginx configuration test failed!"
    exit 1
fi

echo "Nginx configuration is valid"
echo "Starting nginx on 0.0.0.0:${PORT}..."

# Ensure nginx can write to its directories
mkdir -p /var/cache/nginx/client_temp
mkdir -p /var/cache/nginx/proxy_temp
mkdir -p /var/cache/nginx/fastcgi_temp
mkdir -p /var/cache/nginx/uwsgi_temp
mkdir -p /var/cache/nginx/scgi_temp

# Set proper permissions
chown -R nginx:nginx /var/cache/nginx 2>/dev/null || true
chown -R nginx:nginx /var/log/nginx 2>/dev/null || true

# Verify nginx binary exists and is executable
if [ ! -f /usr/sbin/nginx ]; then
    echo "ERROR: nginx binary not found!"
    exit 1
fi

echo "Starting nginx process..."
echo "Nginx will listen on 0.0.0.0:${PORT}"
echo "Process info:"
ps aux | head -5 || true

# Start nginx in foreground - this is critical for Cloud Run
# Use exec to replace shell process with nginx
# This ensures Cloud Run sees nginx as the main process
exec /usr/sbin/nginx -g "daemon off;"

