FROM python:3.12-slim

WORKDIR /app

# Install FFmpeg for yt-dlp and tini for proper PID 1 handling (T028)
RUN apt-get update && apt-get install -y ffmpeg tini && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Use tini as init system to prevent zombie processes (T028)
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
