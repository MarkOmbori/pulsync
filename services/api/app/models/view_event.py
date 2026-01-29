import uuid
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db import Base


class ViewEvent(Base):
    __tablename__ = "view_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    content_id = Column(
        UUID(as_uuid=True),
        ForeignKey("contents.id", ondelete="CASCADE"),
        nullable=False,
    )
    view_duration_seconds = Column(Integer, default=0)
    completion_percent = Column(Float, default=0.0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    user = relationship("User", back_populates="view_events")
    content = relationship("Content", back_populates="view_events")
