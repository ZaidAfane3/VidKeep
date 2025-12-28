from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://vidkeep:vidkeep@postgres:5432/vidkeep"
    redis_url: str = "redis://redis:6379"
    data_path: str = "/data"
    max_video_height: int = 1080
    worker_count: int = 2

    class Config:
        env_file = ".env"


settings = Settings()
