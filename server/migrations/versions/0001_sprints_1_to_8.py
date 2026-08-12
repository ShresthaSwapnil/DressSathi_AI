"""Complete DressMate schema through Sprint 8.

Revision ID: 0001_sprints_1_to_8
Revises:
"""

import sqlalchemy as sa
from alembic import op

# Importing models registers every table on Base.metadata.
import models  # noqa: F401
from database import Base

revision = "0001_sprints_1_to_8"
down_revision = None
branch_labels = None
depends_on = None


def _columns(inspector, table):
    return {column["name"] for column in inspector.get_columns(table)}


def upgrade():
    bind = op.get_bind()
    Base.metadata.create_all(bind=bind)
    inspector = sa.inspect(bind)

    additions = {
        "users": [
            sa.Column("display_name", sa.String(length=100)),
            sa.Column("style_preferences", sa.Text()),
            sa.Column("location_name", sa.String(length=120)),
            sa.Column("latitude", sa.Float()),
            sa.Column("longitude", sa.Float()),
        ],
        "saved_outfits": [
            sa.Column("title", sa.String(length=160)),
            sa.Column("provider", sa.String(length=30)),
            sa.Column("model_used", sa.String(length=100)),
            sa.Column("confidence_score", sa.Float()),
        ],
        "friendships": [
            sa.Column("pair_key", sa.String(length=60)),
            sa.Column("updated_at", sa.DateTime()),
        ],
    }
    for table, columns in additions.items():
        existing = _columns(inspector, table)
        for column in columns:
            if column.name not in existing:
                op.add_column(table, column)


def downgrade():
    # ponytail: preserve user data; destructive downgrade can be added if rollback is required.
    pass
