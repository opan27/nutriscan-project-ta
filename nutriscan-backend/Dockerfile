FROM node:20-alpine

WORKDIR /app

# Install dependencies production only
COPY package*.json ./
RUN npm ci --omit=dev

# Copy source code
COPY . .

# Buat direktori uploads
RUN mkdir -p uploads

EXPOSE 3000

CMD ["node", "server.js"]
