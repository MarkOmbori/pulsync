from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.models.content import ContentType, SharingPolicy
from app.schemas.tag import Tag
from app.schemas.user import UserPublic


class ContentBase(BaseModel):
    content_type: ContentType = ContentType.TEXT
    title: str | None = None
    body: str | None = None
    media_url: str | None = None
    thumbnail_url: str | None = None
    duration_seconds: int | None = None
    is_company_important: bool = False
    sharing_policy: SharingPolicy = SharingPolicy.INTERNAL_ONLY
    comments_enabled: bool = True
    target_roles: list[str] | None = None


class ContentCreate(ContentBase):
    tag_ids: list[UUID] | None = None


class ContentUpdate(BaseModel):
    title: str | None = None
    body: str | None = None
    media_url: str | None = None
    thumbnail_url: str | None = None
    duration_seconds: int | None = None
    is_company_important: bool | None = None
    sharing_policy: SharingPolicy | None = None
    comments_enabled: bool | None = None
    target_roles: list[str] | None = None
    tag_ids: list[UUID] | None = None


class Content(ContentBase):
    id: UUID
    author_id: UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ContentWithDetails(Content):
    author: UserPublic
    tags: list[Tag] = []
    like_count: int = 0
    comment_count: int = 0
    is_liked: bool = False
    is_bookmarked: bool = False


class ContentFeedItem(BaseModel):
    id: UUID
    author: UserPublic
    content_type: ContentType
    title: str | None = None
    body: str | None = None
    media_url: str | None = None
    thumbnail_url: str | None = None
    duration_seconds: int | None = None
    is_company_important: bool
    tags: list[Tag] = []
    like_count: int = 0
    comment_count: int = 0
    is_liked: bool = False
    is_bookmarked: bool = False
    created_at: datetime

    class Config:
        from_attributes = True
