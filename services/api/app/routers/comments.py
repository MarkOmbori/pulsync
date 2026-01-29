from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.models.comment import Comment as CommentModel
from app.models.content import Content as ContentModel
from app.models.user import User as UserModel
from app.routers.auth import get_current_user
from app.schemas.comment import CommentCreate, CommentUpdate, CommentWithAuthor

router = APIRouter(tags=["comments"])


@router.get("/content/{content_id}/comments", response_model=list[CommentWithAuthor])
async def get_comments(
    content_id: UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """Get comments for a content item."""
    content = db.query(ContentModel).filter(ContentModel.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Content not found"
        )

    if not content.comments_enabled:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Comments are disabled for this content",
        )

    # Get top-level comments (no parent)
    comments = (
        db.query(CommentModel)
        .options(joinedload(CommentModel.author))
        .filter(CommentModel.content_id == content_id, CommentModel.parent_id == None)  # noqa: E711
        .order_by(CommentModel.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    result = []
    for comment in comments:
        reply_count = (
            db.query(func.count(CommentModel.id))
            .filter(CommentModel.parent_id == comment.id)
            .scalar()
        )
        result.append(
            CommentWithAuthor(
                id=comment.id,
                content_id=comment.content_id,
                author_id=comment.author_id,
                parent_id=comment.parent_id,
                body=comment.body,
                created_at=comment.created_at,
                updated_at=comment.updated_at,
                author=comment.author,
                reply_count=reply_count,
            )
        )

    return result


@router.get(
    "/content/{content_id}/comments/{comment_id}/replies",
    response_model=list[CommentWithAuthor],
)
async def get_comment_replies(
    content_id: UUID,
    comment_id: UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """Get replies to a comment."""
    replies = (
        db.query(CommentModel)
        .options(joinedload(CommentModel.author))
        .filter(
            CommentModel.content_id == content_id, CommentModel.parent_id == comment_id
        )
        .order_by(CommentModel.created_at.asc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    result = []
    for reply in replies:
        reply_count = (
            db.query(func.count(CommentModel.id))
            .filter(CommentModel.parent_id == reply.id)
            .scalar()
        )
        result.append(
            CommentWithAuthor(
                id=reply.id,
                content_id=reply.content_id,
                author_id=reply.author_id,
                parent_id=reply.parent_id,
                body=reply.body,
                created_at=reply.created_at,
                updated_at=reply.updated_at,
                author=reply.author,
                reply_count=reply_count,
            )
        )

    return result


@router.post(
    "/content/{content_id}/comments",
    response_model=CommentWithAuthor,
    status_code=status.HTTP_201_CREATED,
)
async def create_comment(
    content_id: UUID,
    comment_data: CommentCreate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Add a comment to content."""
    content = db.query(ContentModel).filter(ContentModel.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Content not found"
        )

    if not content.comments_enabled:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Comments are disabled for this content",
        )

    # Validate parent comment if provided
    if comment_data.parent_id:
        parent = (
            db.query(CommentModel)
            .filter(
                CommentModel.id == comment_data.parent_id,
                CommentModel.content_id == content_id,
            )
            .first()
        )
        if not parent:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Parent comment not found",
            )

    comment = CommentModel(
        content_id=content_id,
        author_id=current_user.id,
        parent_id=comment_data.parent_id,
        body=comment_data.body,
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)

    return CommentWithAuthor(
        id=comment.id,
        content_id=comment.content_id,
        author_id=comment.author_id,
        parent_id=comment.parent_id,
        body=comment.body,
        created_at=comment.created_at,
        updated_at=comment.updated_at,
        author=current_user,
        reply_count=0,
    )


@router.patch("/comments/{comment_id}", response_model=CommentWithAuthor)
async def update_comment(
    comment_id: UUID,
    comment_data: CommentUpdate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a comment (author only)."""
    comment = (
        db.query(CommentModel)
        .options(joinedload(CommentModel.author))
        .filter(CommentModel.id == comment_id)
        .first()
    )
    if not comment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Comment not found"
        )

    if comment.author_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized"
        )

    comment.body = comment_data.body
    db.commit()
    db.refresh(comment)

    reply_count = (
        db.query(func.count(CommentModel.id))
        .filter(CommentModel.parent_id == comment.id)
        .scalar()
    )

    return CommentWithAuthor(
        id=comment.id,
        content_id=comment.content_id,
        author_id=comment.author_id,
        parent_id=comment.parent_id,
        body=comment.body,
        created_at=comment.created_at,
        updated_at=comment.updated_at,
        author=comment.author,
        reply_count=reply_count,
    )


@router.delete("/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_comment(
    comment_id: UUID,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a comment (author or comms team)."""
    comment = db.query(CommentModel).filter(CommentModel.id == comment_id).first()
    if not comment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Comment not found"
        )

    if comment.author_id != current_user.id and not current_user.is_comms_team:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized"
        )

    db.delete(comment)
    db.commit()
