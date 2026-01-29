from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.models.conversation import Conversation as ConversationModel
from app.models.conversation import ConversationParticipant as ParticipantModel
from app.models.message import Message as MessageModel
from app.models.user import User as UserModel
from app.routers.auth import get_current_user
from app.schemas.message import (
    Conversation,
    ConversationCreate,
    ConversationParticipant,
    ConversationWithMessages,
    MessageCreate,
    MessageWithSender,
)
from app.schemas.user import UserPublic

router = APIRouter(prefix="/messages", tags=["messages"])


def get_conversation_response(
    conversation: ConversationModel, current_user_id: UUID, db: Session
) -> Conversation:
    """Build a Conversation response with last message and unread count."""
    # Get last message
    last_message_model = (
        db.query(MessageModel)
        .options(joinedload(MessageModel.sender))
        .filter(MessageModel.conversation_id == conversation.id)
        .order_by(MessageModel.created_at.desc())
        .first()
    )

    last_message = None
    if last_message_model:
        last_message = MessageWithSender(
            id=last_message_model.id,
            conversation_id=last_message_model.conversation_id,
            sender_id=last_message_model.sender_id,
            body=last_message_model.body,
            created_at=last_message_model.created_at,
            updated_at=last_message_model.updated_at,
            sender=last_message_model.sender,
        )

    # Get current user's participant record for unread count
    current_participant = (
        db.query(ParticipantModel)
        .filter(
            ParticipantModel.conversation_id == conversation.id,
            ParticipantModel.user_id == current_user_id,
        )
        .first()
    )

    unread_count = 0
    if current_participant and current_participant.last_read_at:
        unread_count = (
            db.query(func.count(MessageModel.id))
            .filter(
                MessageModel.conversation_id == conversation.id,
                MessageModel.created_at > current_participant.last_read_at,
                MessageModel.sender_id != current_user_id,
            )
            .scalar()
        )
    elif current_participant:
        # Never read - count all messages from others
        unread_count = (
            db.query(func.count(MessageModel.id))
            .filter(
                MessageModel.conversation_id == conversation.id,
                MessageModel.sender_id != current_user_id,
            )
            .scalar()
        )

    # Build participants with user info
    participants = []
    for p in conversation.participants:
        participants.append(
            ConversationParticipant(
                id=p.id,
                conversation_id=p.conversation_id,
                user_id=p.user_id,
                joined_at=p.joined_at,
                last_read_at=p.last_read_at,
                user=p.user,
            )
        )

    return Conversation(
        id=conversation.id,
        created_at=conversation.created_at,
        updated_at=conversation.updated_at,
        participants=participants,
        last_message=last_message,
        unread_count=unread_count,
    )


@router.get("/conversations", response_model=list[Conversation])
async def list_conversations(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List the current user's conversations."""
    # Get conversation IDs where user is a participant
    conversation_ids = (
        db.query(ParticipantModel.conversation_id)
        .filter(ParticipantModel.user_id == current_user.id)
        .subquery()
    )

    conversations = (
        db.query(ConversationModel)
        .options(
            joinedload(ConversationModel.participants).joinedload(ParticipantModel.user)
        )
        .filter(ConversationModel.id.in_(conversation_ids))
        .order_by(ConversationModel.updated_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    return [get_conversation_response(c, current_user.id, db) for c in conversations]


@router.post(
    "/conversations", response_model=Conversation, status_code=status.HTTP_201_CREATED
)
async def create_conversation(
    data: ConversationCreate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new conversation with specified participants."""
    # Validate participants exist
    participant_ids = set(data.participant_ids)
    participant_ids.add(current_user.id)  # Always include current user

    if len(participant_ids) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Conversation must have at least 2 participants",
        )

    existing_users = db.query(UserModel).filter(UserModel.id.in_(participant_ids)).all()
    if len(existing_users) != len(participant_ids):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="One or more participants not found",
        )

    # Check if a 1:1 conversation already exists between these users
    if len(participant_ids) == 2:
        # Find conversations where both users are participants
        existing = (
            db.query(ConversationModel)
            .join(ParticipantModel)
            .filter(ParticipantModel.user_id == current_user.id)
            .all()
        )

        for conv in existing:
            conv_participant_ids = {p.user_id for p in conv.participants}
            if conv_participant_ids == participant_ids:
                # Return existing conversation
                db.refresh(conv)
                return get_conversation_response(conv, current_user.id, db)

    # Create new conversation
    conversation = ConversationModel()
    db.add(conversation)
    db.flush()

    # Add participants
    for user_id in participant_ids:
        participant = ParticipantModel(
            conversation_id=conversation.id,
            user_id=user_id,
        )
        db.add(participant)

    # Add initial message if provided
    if data.initial_message:
        message = MessageModel(
            conversation_id=conversation.id,
            sender_id=current_user.id,
            body=data.initial_message,
        )
        db.add(message)

    db.commit()

    # Reload with relationships
    conversation = (
        db.query(ConversationModel)
        .options(
            joinedload(ConversationModel.participants).joinedload(ParticipantModel.user)
        )
        .filter(ConversationModel.id == conversation.id)
        .first()
    )

    return get_conversation_response(conversation, current_user.id, db)


@router.get("/conversations/{conversation_id}", response_model=ConversationWithMessages)
async def get_conversation(
    conversation_id: UUID,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get a conversation with all its messages."""
    # Verify user is a participant
    participant = (
        db.query(ParticipantModel)
        .filter(
            ParticipantModel.conversation_id == conversation_id,
            ParticipantModel.user_id == current_user.id,
        )
        .first()
    )

    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )

    conversation = (
        db.query(ConversationModel)
        .options(
            joinedload(ConversationModel.participants).joinedload(ParticipantModel.user)
        )
        .filter(ConversationModel.id == conversation_id)
        .first()
    )

    # Get messages with senders
    messages = (
        db.query(MessageModel)
        .options(joinedload(MessageModel.sender))
        .filter(MessageModel.conversation_id == conversation_id)
        .order_by(MessageModel.created_at.asc())
        .all()
    )

    # Update last_read_at
    participant.last_read_at = datetime.now(timezone.utc)
    db.commit()

    # Build participants
    participants = [
        ConversationParticipant(
            id=p.id,
            conversation_id=p.conversation_id,
            user_id=p.user_id,
            joined_at=p.joined_at,
            last_read_at=p.last_read_at,
            user=p.user,
        )
        for p in conversation.participants
    ]

    # Build messages
    message_list = [
        MessageWithSender(
            id=m.id,
            conversation_id=m.conversation_id,
            sender_id=m.sender_id,
            body=m.body,
            created_at=m.created_at,
            updated_at=m.updated_at,
            sender=m.sender,
        )
        for m in messages
    ]

    return ConversationWithMessages(
        id=conversation.id,
        created_at=conversation.created_at,
        updated_at=conversation.updated_at,
        participants=participants,
        messages=message_list,
    )


@router.delete(
    "/conversations/{conversation_id}", status_code=status.HTTP_204_NO_CONTENT
)
async def leave_conversation(
    conversation_id: UUID,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Leave a conversation (remove self as participant)."""
    participant = (
        db.query(ParticipantModel)
        .filter(
            ParticipantModel.conversation_id == conversation_id,
            ParticipantModel.user_id == current_user.id,
        )
        .first()
    )

    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )

    db.delete(participant)

    # If no participants left, delete the conversation
    remaining = (
        db.query(func.count(ParticipantModel.id))
        .filter(ParticipantModel.conversation_id == conversation_id)
        .scalar()
    )

    if remaining == 0:
        conversation = (
            db.query(ConversationModel)
            .filter(ConversationModel.id == conversation_id)
            .first()
        )
        if conversation:
            db.delete(conversation)

    db.commit()


@router.get(
    "/conversations/{conversation_id}/messages", response_model=list[MessageWithSender]
)
async def get_messages(
    conversation_id: UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get paginated messages from a conversation."""
    # Verify user is a participant
    participant = (
        db.query(ParticipantModel)
        .filter(
            ParticipantModel.conversation_id == conversation_id,
            ParticipantModel.user_id == current_user.id,
        )
        .first()
    )

    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )

    messages = (
        db.query(MessageModel)
        .options(joinedload(MessageModel.sender))
        .filter(MessageModel.conversation_id == conversation_id)
        .order_by(MessageModel.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    # Reverse to get chronological order
    messages = list(reversed(messages))

    return [
        MessageWithSender(
            id=m.id,
            conversation_id=m.conversation_id,
            sender_id=m.sender_id,
            body=m.body,
            created_at=m.created_at,
            updated_at=m.updated_at,
            sender=m.sender,
        )
        for m in messages
    ]


@router.post(
    "/conversations/{conversation_id}/messages",
    response_model=MessageWithSender,
    status_code=status.HTTP_201_CREATED,
)
async def send_message(
    conversation_id: UUID,
    data: MessageCreate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Send a message to a conversation."""
    # Verify user is a participant
    participant = (
        db.query(ParticipantModel)
        .filter(
            ParticipantModel.conversation_id == conversation_id,
            ParticipantModel.user_id == current_user.id,
        )
        .first()
    )

    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )

    message = MessageModel(
        conversation_id=conversation_id,
        sender_id=current_user.id,
        body=data.body,
    )
    db.add(message)

    # Update conversation's updated_at
    conversation = (
        db.query(ConversationModel)
        .filter(ConversationModel.id == conversation_id)
        .first()
    )
    conversation.updated_at = datetime.now(timezone.utc)

    # Update sender's last_read_at
    participant.last_read_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(message)

    return MessageWithSender(
        id=message.id,
        conversation_id=message.conversation_id,
        sender_id=message.sender_id,
        body=message.body,
        created_at=message.created_at,
        updated_at=message.updated_at,
        sender=current_user,
    )


@router.get("/users/search", response_model=list[UserPublic])
async def search_users(
    q: str = Query(..., min_length=1),
    limit: int = Query(20, ge=1, le=50),
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Search users by name or email for starting a new conversation."""
    search_term = f"%{q}%"

    users = (
        db.query(UserModel)
        .filter(
            UserModel.id != current_user.id,
            or_(
                UserModel.display_name.ilike(search_term),
                UserModel.email.ilike(search_term),
            ),
        )
        .limit(limit)
        .all()
    )

    return [
        UserPublic(
            id=u.id,
            display_name=u.display_name,
            avatar_url=u.avatar_url,
            role=u.role,
            department=u.department,
        )
        for u in users
    ]
