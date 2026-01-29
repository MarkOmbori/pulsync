import uuid

from sqlalchemy import Column, ForeignKey, String, Table
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db import Base

# Association table for Content-Tag many-to-many relationship
content_tag_association = Table(
    "content_tag_association",
    Base.metadata,
    Column(
        "content_id",
        UUID(as_uuid=True),
        ForeignKey("contents.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "tag_id",
        UUID(as_uuid=True),
        ForeignKey("tags.id", ondelete="CASCADE"),
        primary_key=True,
    ),
)


class Tag(Base):
    __tablename__ = "tags"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    slug = Column(String, unique=True, index=True, nullable=False)
    category = Column(String, nullable=True)

    # Relationships
    contents = relationship(
        "Content", secondary=content_tag_association, back_populates="tags"
    )
    user_interests = relationship("UserInterest", back_populates="tag")
