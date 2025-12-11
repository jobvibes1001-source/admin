# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Note: Environment variables are set via ARG/ENV above
# If .env.production exists, it will be included in the COPY . . above

# Build the application with production environment
# Vite will use .env.production automatically when NODE_ENV=production
ARG VITE_API_BASE_URL=https://node-git-796530532940.asia-south1.run.app/api
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
ENV NODE_ENV=production

RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built files from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Verify that index.html exists (build was successful)
RUN test -f /usr/share/nginx/html/index.html || (echo "ERROR: index.html not found. Build may have failed." && exit 1)

# Copy nginx configuration (binds to 0.0.0.0:8080 for Cloud Run)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Remove default nginx config if it exists
RUN rm -f /etc/nginx/conf.d/default.conf.bak 2>/dev/null || true

# Test nginx configuration during build
RUN nginx -t

# Expose port 8080 (Cloud Run default)
EXPOSE 8080

# Start nginx in foreground mode
CMD ["nginx", "-g", "daemon off;"]

