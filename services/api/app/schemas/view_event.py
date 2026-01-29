from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class ViewEventCreate(BaseModel):
    content_id: UUID
    view_duration_seconds: int = 0
    completion_percent: float = 0.0


class ViewEvent(BaseModel):
    id: UUID
    user_id: UUID
    content_id: UUID
    view_duration_seconds: int
    completion_percent: float
    created_at: datetime

    class Config:
        from_attributes = True
