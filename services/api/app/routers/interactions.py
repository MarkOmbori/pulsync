from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.models.bookmark import Bookmark
from app.models.content import Content as ContentModel
from app.models.like import Like
from app.models.user import User as UserModel
from app.routers.auth import get_current_user
from app.schemas.content import Content, ContentWithDetails

router = APIRouter(tags=["interactions"])


@router.post("/content/{content_id}/like")
async def toggle_like(
    content_id: UUID,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Toggle like on content."""
    content = db.query(ContentModel).filter(ContentModel.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Content not found"
        )

    existing_like = (
        db.query(Like)
        .filter(Like.content_id == content_id, Like.user_id == current_user.id)
        .first()
    )

    if existing_like:
        db.delete(existing_like)
        db.commit()
        return {"status": "unliked", "is_liked": False}
    else:
        like = Like(content_id=content_id, user_id=current_user.id)
        db.add(like)
        db.commit()
        return {"status": "liked", "is_liked": True}


@router.post("/content/{content_id}/bookmark")
async def toggle_bookmark(
    content_id: UUID,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Toggle bookmark on content."""
    content = db.query(ContentModel).filter(ContentModel.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Content not found"
        )

    existing_bookmark = (
        db.query(Bookmark)
        .filter(Bookmark.content_id == content_id, Bookmark.user_id == current_user.id)
        .first()
    )

    if existing_bookmark:
        db.delete(existing_bookmark)
        db.commit()
        return {"status": "unbookmarked", "is_bookmarked": False}
    else:
        bookmark = Bookmark(content_id=content_id, user_id=current_user.id)
        db.add(bookmark)
        db.commit()
        return {"status": "bookmarked", "is_bookmarked": True}


@router.get("/bookmarks", response_model=list[ContentWithDetails])
async def get_bookmarks(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get user's bookmarked content."""
    from sqlalchemy import func

    from app.models.comment import Comment

    bookmarks = (
        db.query(Bookmark)
        .filter(Bookmark.user_id == current_user.id)
        .order_by(Bookmark.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    content_ids = [b.content_id for b in bookmarks]
    contents = (
        db.query(ContentModel)
        .options(joinedload(ContentModel.author), joinedload(ContentModel.tags))
        .filter(ContentModel.id.in_(content_ids))
        .all()
    )

    # Maintain bookmark order
    content_map = {c.id: c for c in contents}
    ordered_contents = [content_map[cid] for cid in content_ids if cid in content_map]

    result = []
    for content in ordered_contents:
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
        is_liked = (
            db.query(Like)
            .filter(Like.content_id == content.id, Like.user_id == current_user.id)
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
                is_bookmarked=True,
            )
        )

    return result


@router.get("/likes", response_model=list[ContentWithDetails])
async def get_liked_content(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get user's liked content."""
    from sqlalchemy import func

    from app.models.comment import Comment

    likes = (
        db.query(Like)
        .filter(Like.user_id == current_user.id)
        .order_by(Like.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    content_ids = [like.content_id for like in likes]
    contents = (
        db.query(ContentModel)
        .options(joinedload(ContentModel.author), joinedload(ContentModel.tags))
        .filter(ContentModel.id.in_(content_ids))
        .all()
    )

    content_map = {c.id: c for c in contents}
    ordered_contents = [content_map[cid] for cid in content_ids if cid in content_map]

    result = []
    for content in ordered_contents:
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
        is_bookmarked = (
            db.query(Bookmark)
            .filter(
                Bookmark.content_id == content.id, Bookmark.user_id == current_user.id
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
                is_liked=True,
                is_bookmarked=is_bookmarked,
            )
        )

    return result
