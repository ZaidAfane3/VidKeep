"""Add job tracking columns

Revision ID: 002_add_job_tracking
Revises: 001_create_videos_table
Create Date: 2026-01-06

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('videos', sa.Column('claimed_by', sa.String(100), nullable=True))
    op.add_column('videos', sa.Column('claimed_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('videos', sa.Column('retry_count', sa.Integer(), server_default='0', nullable=False))


def downgrade() -> None:
    op.drop_column('videos', 'retry_count')
    op.drop_column('videos', 'claimed_at')
    op.drop_column('videos', 'claimed_by')
