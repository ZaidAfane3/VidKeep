# Build frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ .
RUN npm run build

# Build backend with embedded frontend
FROM python:3.12-slim
WORKDIR /app

# Install FFmpeg for yt-dlp and tini for proper PID 1 handling (T028)
RUN apt-get update && apt-get install -y ffmpeg tini && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY backend/ .

# Copy frontend build to static directory (T026 Monolith Merge)
COPY --from=frontend-builder /frontend/dist /app/static

# Make startup script executable
RUN chmod +x /app/startup.sh

# Expose port
EXPOSE 8000

# Use tini as init system to prevent zombie processes (T028)
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/app/startup.sh"]
