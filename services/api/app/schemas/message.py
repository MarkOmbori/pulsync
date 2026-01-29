from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.schemas.user import UserPublic


class MessageBase(BaseModel):
    body: str


class MessageCreate(MessageBase):
    pass


class Message(MessageBase):
    id: UUID
    conversation_id: UUID
    sender_id: UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class MessageWithSender(Message):
    sender: UserPublic


class ConversationParticipantBase(BaseModel):
    user_id: UUID


class ConversationParticipant(ConversationParticipantBase):
    id: UUID
    conversation_id: UUID
    joined_at: datetime
    last_read_at: datetime | None = None
    user: UserPublic

    class Config:
        from_attributes = True


class ConversationCreate(BaseModel):
    participant_ids: list[UUID]
    initial_message: str | None = None


class ConversationBase(BaseModel):
    id: UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class Conversation(ConversationBase):
    participants: list[ConversationParticipant]
    last_message: MessageWithSender | None = None
    unread_count: int = 0


class ConversationWithMessages(ConversationBase):
    participants: list[ConversationParticipant]
    messages: list[MessageWithSender]
