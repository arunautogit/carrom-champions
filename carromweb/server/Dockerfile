# Dockerfile for GCP Cloud Run / Compute Engine
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package manifests & install production dependencies
COPY package*.json ./
RUN npm install --production

# Copy server application
COPY . .

# GCP Cloud Run automatically specifies the PORT environment variable (default 8080)
ENV PORT=8080
EXPOSE 8080

# Launch server
CMD ["node", "server.js"]
