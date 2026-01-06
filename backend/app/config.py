from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://vidkeep:vidkeep@postgres:5432/vidkeep"
    redis_url: str = "redis://redis:6379"
    data_path: str = "/data"
    max_video_height: int = 1080

    # Embedded worker config (T028)
    max_workers: int = 1
    worker_heartbeat_interval: int = 10
    worker_heartbeat_ttl: int = 30
    stale_job_threshold_seconds: int = 60
    max_download_retries: int = 3
    pod_name: str = "pod-unknown"

    class Config:
        env_file = ".env"


settings = Settings()
