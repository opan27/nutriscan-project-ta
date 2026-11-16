# ─── Stage 1: Build React App ────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Build args untuk environment
ARG VITE_API_BASE=""
ENV VITE_API_BASE=$VITE_API_BASE

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ─── Stage 2: Serve dengan Nginx ─────────────────────────────────────────────
FROM nginx:alpine

# Copy hasil build
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy konfigurasi Nginx kustom
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
