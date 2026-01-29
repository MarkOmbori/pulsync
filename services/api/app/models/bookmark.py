from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db import Base


class Bookmark(Base):
    __tablename__ = "bookmarks"

    user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    content_id = Column(
        UUID(as_uuid=True),
        ForeignKey("contents.id", ondelete="CASCADE"),
        primary_key=True,
    )
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    user = relationship("User", back_populates="bookmarks")
    content = relationship("Content", back_populates="bookmarks")
