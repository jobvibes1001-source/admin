# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Copy production environment file
COPY .env.production .env

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

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Test nginx configuration
RUN nginx -t

# Expose port 8080 (Cloud Run default)
EXPOSE 8080

# Start nginx in foreground mode
CMD ["nginx", "-g", "daemon off;"]

