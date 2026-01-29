import uuid
from datetime import datetime, timezone
from enum import Enum

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import relationship

from app.db import Base
from app.models.tag import content_tag_association


class ContentType(str, Enum):
    TEXT = "text"
    VIDEO = "video"
    AUDIO = "audio"


class SharingPolicy(str, Enum):
    INTERNAL_ONLY = "internal_only"
    EXTERNAL_ALLOWED = "external_allowed"


class Content(Base):
    __tablename__ = "contents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    author_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    content_type = Column(String, nullable=False, default=ContentType.TEXT.value)
    title = Column(String, nullable=True)
    body = Column(String, nullable=True)
    media_url = Column(String, nullable=True)
    thumbnail_url = Column(String, nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    is_company_important = Column(Boolean, default=False)
    sharing_policy = Column(String, default=SharingPolicy.INTERNAL_ONLY.value)
    comments_enabled = Column(Boolean, default=True)
    target_roles = Column(ARRAY(String), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    author = relationship("User", back_populates="contents")
    tags = relationship(
        "Tag", secondary=content_tag_association, back_populates="contents"
    )
    comments = relationship(
        "Comment", back_populates="content", cascade="all, delete-orphan"
    )
    likes = relationship("Like", back_populates="content", cascade="all, delete-orphan")
    bookmarks = relationship(
        "Bookmark", back_populates="content", cascade="all, delete-orphan"
    )
    view_events = relationship(
        "ViewEvent", back_populates="content", cascade="all, delete-orphan"
    )
