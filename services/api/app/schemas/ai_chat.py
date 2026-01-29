from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class AIChatMessageBase(BaseModel):
    content: str


class AIChatMessageCreate(AIChatMessageBase):
    pass


class AIChatMessage(AIChatMessageBase):
    id: UUID
    session_id: UUID
    role: str
    created_at: datetime

    class Config:
        from_attributes = True


class AIChatSessionCreate(BaseModel):
    title: str | None = None


class AIChatSessionBase(BaseModel):
    id: UUID
    title: str | None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class AIChatSession(AIChatSessionBase):
    pass


class AIChatSessionWithMessages(AIChatSessionBase):
    messages: list[AIChatMessage]
