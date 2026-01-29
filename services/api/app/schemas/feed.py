from uuid import UUID

from pydantic import BaseModel

from app.schemas.content import ContentFeedItem


class FeedResponse(BaseModel):
    items: list[ContentFeedItem]
    next_cursor: str | None = None
    has_more: bool = False


class UserInterestBase(BaseModel):
    tag_id: UUID
    score: float = 0.0
    is_auto_subscribed: bool = False
    is_manually_followed: bool = False


class UserInterest(UserInterestBase):
    user_id: UUID

    class Config:
        from_attributes = True


class FollowTagRequest(BaseModel):
    follow: bool = True
