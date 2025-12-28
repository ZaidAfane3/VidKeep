from pydantic import BaseModel, Field, computed_field
from datetime import date, datetime
from typing import Optional
from enum import Enum


class VideoStatus(str, Enum):
    pending = "pending"
    downloading = "downloading"
    complete = "complete"
    failed = "failed"


class VideoBase(BaseModel):
    title: str
    channel_name: str
    channel_id: Optional[str] = None
    duration_seconds: Optional[int] = None
    upload_date: Optional[date] = None
    description: Optional[str] = None


class VideoCreate(BaseModel):
    url: str = Field(..., description="YouTube URL to ingest")


class VideoUpdate(BaseModel):
    is_favorite: Optional[bool] = None


class VideoResponse(VideoBase):
    video_id: str
    is_favorite: bool
    status: VideoStatus
    file_size_bytes: Optional[int] = None
    created_at: datetime
    error_message: Optional[str] = None
    download_progress: Optional[int] = None  # 0-100, only during downloading

    @computed_field
    @property
    def youtube_url(self) -> str:
        return f"https://www.youtube.com/watch?v={self.video_id}"

    class Config:
        from_attributes = True


class VideoListResponse(BaseModel):
    videos: list[VideoResponse]
    total: int


class IngestResponse(BaseModel):
    video_id: str
    message: str


class ChannelResponse(BaseModel):
    channel_name: str
    video_count: int


class ChannelListResponse(BaseModel):
    channels: list[ChannelResponse]
