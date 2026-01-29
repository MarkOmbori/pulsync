import uuid
from enum import Enum

from sqlalchemy import Boolean, Column, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db import Base


class UserRole(str, Enum):
    ENGINEERING = "engineering"
    HR = "hr"
    MARKETING = "marketing"
    COMMS = "comms"
    EXECUTIVE = "executive"


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, index=True, nullable=False)
    display_name = Column(String, nullable=False)
    avatar_url = Column(String, nullable=True)
    role = Column(String, nullable=False, default=UserRole.ENGINEERING.value)
    department = Column(String, nullable=False, default="")
    is_comms_team = Column(Boolean, default=False)

    # Relationships
    contents = relationship("Content", back_populates="author")
    comments = relationship("Comment", back_populates="author")
    likes = relationship("Like", back_populates="user")
    bookmarks = relationship("Bookmark", back_populates="user")
    view_events = relationship("ViewEvent", back_populates="user")
    interests = relationship("UserInterest", back_populates="user")
