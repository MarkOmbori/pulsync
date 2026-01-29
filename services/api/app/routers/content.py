from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.models.bookmark import Bookmark
from app.models.comment import Comment
from app.models.content import Content as ContentModel
from app.models.like import Like
from app.models.tag import Tag as TagModel
from app.models.user import User as UserModel
from app.routers.auth import get_current_user, get_current_user_optional
from app.schemas.content import (
    Content,
    ContentCreate,
    ContentUpdate,
    ContentWithDetails,
)

router = APIRouter(prefix="/content", tags=["content"])


@router.get("", response_model=list[ContentWithDetails])
async def list_content(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    content_type: str | None = None,
    current_user: UserModel | None = Depends(get_current_user_optional),
    db: Session = Depends(get_db),
):
    """List all content with pagination."""
    query = db.query(ContentModel).options(
        joinedload(ContentModel.author), joinedload(ContentModel.tags)
    )

    if content_type:
        query = query.filter(ContentModel.content_type == content_type)

    query = query.order_by(ContentModel.created_at.desc())
    contents = query.offset(skip).limit(limit).all()

    result = []
    for content in contents:
        like_count = (
            db.query(func.count(Like.user_id))
            .filter(Like.content_id == content.id)
            .scalar()
        )
        comment_count = (
            db.query(func.count(Comment.id))
            .filter(Comment.content_id == content.id)
            .scalar()
        )

        is_liked = False
        is_bookmarked = False
        if current_user:
            is_liked = (
                db.query(Like)
                .filter(Like.content_id == content.id, Like.user_id == current_user.id)
                .first()
                is not None
            )
            is_bookmarked = (
                db.query(Bookmark)
                .filter(
                    Bookmark.content_id == content.id,
                    Bookmark.user_id == current_user.id,
                )
                .first()
                is not None
            )

        result.append(
            ContentWithDetails(
                **Content.model_validate(content).model_dump(),
                author=content.author,
                tags=content.tags,
                like_count=like_count,
                comment_count=comment_count,
                is_liked=is_liked,
                is_bookmarked=is_bookmarked,
            )
        )

    return result


@router.post("", response_model=Content, status_code=status.HTTP_201_CREATED)
async def create_content(
    content_data: ContentCreate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create new content."""
    content_dict = content_data.model_dump(exclude={"tag_ids"})
    content = ContentModel(**content_dict, author_id=current_user.id)

    if content_data.tag_ids:
        tags = db.query(TagModel).filter(TagModel.id.in_(content_data.tag_ids)).all()
        content.tags = tags

    db.add(content)
    db.commit()
    db.refresh(content)
    return content


@router.get("/{content_id}", response_model=ContentWithDetails)
async def get_content(
    content_id: UUID,
    current_user: UserModel | None = Depends(get_current_user_optional),
    db: Session = Depends(get_db),
):
    """Get a specific content item."""
    content = (
        db.query(ContentModel)
        .options(joinedload(ContentModel.author), joinedload(ContentModel.tags))
        .filter(ContentModel.id == content_id)
        .first()
    )
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Content not found"
        )

    like_count = (
        db.query(func.count(Like.user_id))
        .filter(Like.content_id == content.id)
        .scalar()
    )
    comment_count = (
        db.query(func.count(Comment.id))
        .filter(Comment.content_id == content.id)
        .scalar()
    )

    is_liked = False
    is_bookmarked = False
    if current_user:
        is_liked = (
            db.query(Like)
            .filter(Like.content_id == content.id, Like.user_id == current_user.id)
            .first()
            is not None
        )
        is_bookmarked = (
            db.query(Bookmark)
            .filter(
                Bookmark.content_id == content.id, Bookmark.user_id == current_user.id
            )
            .first()
            is not None
        )

    return ContentWithDetails(
        **Content.model_validate(content).model_dump(),
        author=content.author,
        tags=content.tags,
        like_count=like_count,
        comment_count=comment_count,
        is_liked=is_liked,
        is_bookmarked=is_bookmarked,
    )


@router.patch("/{content_id}", response_model=Content)
async def update_content(
    content_id: UUID,
    content_data: ContentUpdate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update content (owner only)."""
    content = db.query(ContentModel).filter(ContentModel.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Content not found"
        )

    if content.author_id != current_user.id and not current_user.is_comms_team:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized"
        )

    update_data = content_data.model_dump(exclude_unset=True, exclude={"tag_ids"})
    for key, value in update_data.items():
        setattr(content, key, value)

    if content_data.tag_ids is not None:
        tags = db.query(TagModel).filter(TagModel.id.in_(content_data.tag_ids)).all()
        content.tags = tags

    db.commit()
    db.refresh(content)
    return content


@router.delete("/{content_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_content(
    content_id: UUID,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete content (owner or comms team only)."""
    content = db.query(ContentModel).filter(ContentModel.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Content not found"
        )

    if content.author_id != current_user.id and not current_user.is_comms_team:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized"
        )

    db.delete(content)
    db.commit()
