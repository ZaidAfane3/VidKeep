from sqlalchemy import Column, String, Text, Integer, BigInteger, Boolean, Date, DateTime, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class Video(Base):
    __tablename__ = "videos"

    video_id = Column(String(11), primary_key=True)
    title = Column(Text, nullable=False)
    channel_name = Column(String(255), nullable=False)
    channel_id = Column(String(24), nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    upload_date = Column(Date, nullable=True)
    description = Column(Text, nullable=True)
    is_favorite = Column(Boolean, default=False)
    status = Column(String(20), default="pending")  # pending, downloading, complete, failed
    file_size_bytes = Column(BigInteger, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    error_message = Column(Text, nullable=True)

    __table_args__ = (
        Index("idx_channel_name", "channel_name"),
        Index("idx_is_favorite", "is_favorite"),
        Index("idx_status", "status"),
    )
