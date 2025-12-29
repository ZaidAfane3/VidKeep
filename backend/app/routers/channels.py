from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models import Video
from app.schemas import ChannelListResponse, ChannelResponse

router = APIRouter(prefix="/api/channels", tags=["Channels"])


@router.get("", response_model=ChannelListResponse)
async def list_channels(
    db: AsyncSession = Depends(get_db)
):
    """List unique channel names with video counts."""
    query = (
        select(
            Video.channel_name,
            func.count(Video.video_id).label("video_count")
        )
        .group_by(Video.channel_name)
        .order_by(Video.channel_name)
    )

    result = await db.execute(query)
    channels = result.all()

    return ChannelListResponse(
        channels=[
            ChannelResponse(channel_name=name, video_count=count)
            for name, count in channels
        ]
    )
