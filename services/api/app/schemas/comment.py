from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.schemas.user import UserPublic


class CommentBase(BaseModel):
    body: str


class CommentCreate(CommentBase):
    parent_id: UUID | None = None


class CommentUpdate(BaseModel):
    body: str


class Comment(CommentBase):
    id: UUID
    content_id: UUID
    author_id: UUID
    parent_id: UUID | None = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class CommentWithAuthor(Comment):
    author: UserPublic
    reply_count: int = 0
