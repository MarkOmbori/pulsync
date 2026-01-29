import json
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.models.ai_chat import AIChatMessage as AIChatMessageModel
from app.models.ai_chat import AIChatSession as AIChatSessionModel
from app.models.user import User as UserModel
from app.routers.auth import get_current_user
from app.schemas.ai_chat import (
    AIChatMessage,
    AIChatMessageCreate,
    AIChatSession,
    AIChatSessionCreate,
    AIChatSessionWithMessages,
)
from app.services.ai_service import generate_session_title, stream_ai_response

router = APIRouter(prefix="/ai-chat", tags=["ai-chat"])


@router.get("/sessions", response_model=list[AIChatSession])
async def list_sessions(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List the current user's AI chat sessions."""
    sessions = (
        db.query(AIChatSessionModel)
        .filter(AIChatSessionModel.user_id == current_user.id)
        .order_by(AIChatSessionModel.updated_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    return [
        AIChatSession(
            id=s.id,
            title=s.title,
            created_at=s.created_at,
            updated_at=s.updated_at,
        )
        for s in sessions
    ]


@router.post(
    "/sessions", response_model=AIChatSession, status_code=status.HTTP_201_CREATED
)
async def create_session(
    data: AIChatSessionCreate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new AI chat session."""
    session = AIChatSessionModel(
        user_id=current_user.id,
        title=data.title,
    )
    db.add(session)
    db.commit()
    db.refresh(session)

    return AIChatSession(
        id=session.id,
        title=session.title,
        created_at=session.created_at,
        updated_at=session.updated_at,
    )


@router.get("/sessions/{session_id}", response_model=AIChatSessionWithMessages)
async def get_session(
    session_id: UUID,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get an AI chat session with all its messages."""
    session = (
        db.query(AIChatSessionModel)
        .options(joinedload(AIChatSessionModel.messages))
        .filter(
            AIChatSessionModel.id == session_id,
            AIChatSessionModel.user_id == current_user.id,
        )
        .first()
    )

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )

    messages = [
        AIChatMessage(
            id=m.id,
            session_id=m.session_id,
            role=m.role,
            content=m.content,
            created_at=m.created_at,
        )
        for m in session.messages
    ]

    return AIChatSessionWithMessages(
        id=session.id,
        title=session.title,
        created_at=session.created_at,
        updated_at=session.updated_at,
        messages=messages,
    )


@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(
    session_id: UUID,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete an AI chat session."""
    session = (
        db.query(AIChatSessionModel)
        .filter(
            AIChatSessionModel.id == session_id,
            AIChatSessionModel.user_id == current_user.id,
        )
        .first()
    )

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )

    db.delete(session)
    db.commit()


@router.post("/sessions/{session_id}/messages")
async def send_message(
    session_id: UUID,
    data: AIChatMessageCreate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Send a message and stream AI response via SSE."""
    session = (
        db.query(AIChatSessionModel)
        .options(joinedload(AIChatSessionModel.messages))
        .filter(
            AIChatSessionModel.id == session_id,
            AIChatSessionModel.user_id == current_user.id,
        )
        .first()
    )

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )

    # Save user message
    user_message = AIChatMessageModel(
        session_id=session_id,
        role="user",
        content=data.content,
    )
    db.add(user_message)

    # Set title from first message if not set
    if not session.title:
        session.title = generate_session_title(data.content)

    db.commit()
    db.refresh(user_message)

    # Build message history for AI
    messages = [{"role": m.role, "content": m.content} for m in session.messages]
    messages.append({"role": "user", "content": data.content})

    async def generate():
        """Generate SSE events with streaming AI response."""
        full_response = []

        # Send user message ID first
        yield f"data: {json.dumps({'event': 'user_message', 'id': str(user_message.id)})}\n\n"

        # Stream AI response
        async for chunk in stream_ai_response(messages):
            full_response.append(chunk)
            yield f"data: {json.dumps({'event': 'text', 'content': chunk})}\n\n"

        # Save assistant response to DB
        assistant_content = "".join(full_response)
        if assistant_content:
            # Create a new DB session for the final save
            from app.db import SessionLocal

            save_db = SessionLocal()
            try:
                assistant_message = AIChatMessageModel(
                    session_id=session_id,
                    role="assistant",
                    content=assistant_content,
                )
                save_db.add(assistant_message)

                # Update session's updated_at
                save_session = (
                    save_db.query(AIChatSessionModel)
                    .filter(AIChatSessionModel.id == session_id)
                    .first()
                )
                if save_session:
                    from datetime import datetime, timezone

                    save_session.updated_at = datetime.now(timezone.utc)

                save_db.commit()
                save_db.refresh(assistant_message)

                yield f"data: {json.dumps({'event': 'done', 'assistant_message_id': str(assistant_message.id)})}\n\n"
            finally:
                save_db.close()
        else:
            yield f"data: {json.dumps({'event': 'done'})}\n\n"

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
