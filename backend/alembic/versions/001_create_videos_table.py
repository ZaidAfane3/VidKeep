"""Create videos table

Revision ID: 001
Revises:
Create Date: 2025-12-28

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "videos",
        sa.Column("video_id", sa.String(11), primary_key=True),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("channel_name", sa.String(255), nullable=False),
        sa.Column("channel_id", sa.String(24), nullable=True),
        sa.Column("duration_seconds", sa.Integer(), nullable=True),
        sa.Column("upload_date", sa.Date(), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("is_favorite", sa.Boolean(), server_default="false"),
        sa.Column("status", sa.String(20), server_default="pending"),
        sa.Column("file_size_bytes", sa.BigInteger(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.func.now()),
        sa.Column("error_message", sa.Text(), nullable=True),
    )

    # Create indexes
    op.create_index("idx_channel_name", "videos", ["channel_name"])
    op.create_index("idx_is_favorite", "videos", ["is_favorite"])
    op.create_index("idx_status", "videos", ["status"])


def downgrade() -> None:
    op.drop_index("idx_status", table_name="videos")
    op.drop_index("idx_is_favorite", table_name="videos")
    op.drop_index("idx_channel_name", table_name="videos")
    op.drop_table("videos")
