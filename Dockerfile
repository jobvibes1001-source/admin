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

# Copy startup script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port 8080 (Cloud Run default, but will use PORT env var)
EXPOSE 8080

# Use custom entrypoint script
ENTRYPOINT ["/docker-entrypoint.sh"]

