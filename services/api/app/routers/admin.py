from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.models.comment import Comment
from app.models.content import Content as ContentModel
from app.models.like import Like
from app.models.user import User as UserModel
from app.models.view_event import ViewEvent
from app.routers.auth import get_current_user
from app.schemas.content import Content, ContentWithDetails

router = APIRouter(prefix="/admin", tags=["admin"])


def require_comms_team(
    current_user: UserModel = Depends(get_current_user),
) -> UserModel:
    if not current_user.is_comms_team:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required"
        )
    return current_user


@router.get("/content", response_model=list[ContentWithDetails])
async def list_all_content(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    content_type: str | None = None,
    is_company_important: bool | None = None,
    current_user: UserModel = Depends(require_comms_team),
    db: Session = Depends(get_db),
):
    """List all content for moderation (comms team only)."""
    query = db.query(ContentModel).options(
        joinedload(ContentModel.author), joinedload(ContentModel.tags)
    )

    if content_type:
        query = query.filter(ContentModel.content_type == content_type)
    if is_company_important is not None:
        query = query.filter(ContentModel.is_company_important == is_company_important)

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

        result.append(
            ContentWithDetails(
                **Content.model_validate(content).model_dump(),
                author=content.author,
                tags=content.tags,
                like_count=like_count,
                comment_count=comment_count,
                is_liked=False,
                is_bookmarked=False,
            )
        )

    return result


@router.patch("/content/{content_id}/important")
async def toggle_company_important(
    content_id: UUID,
    is_important: bool = True,
    current_user: UserModel = Depends(require_comms_team),
    db: Session = Depends(get_db),
):
    """Toggle company-important flag on content (comms team only)."""
    content = db.query(ContentModel).filter(ContentModel.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Content not found"
        )

    content.is_company_important = is_important
    db.commit()

    return {"status": "ok", "is_company_important": is_important}


@router.delete("/content/{content_id}", status_code=status.HTTP_204_NO_CONTENT)
async def admin_delete_content(
    content_id: UUID,
    current_user: UserModel = Depends(require_comms_team),
    db: Session = Depends(get_db),
):
    """Delete any content (comms team only)."""
    content = db.query(ContentModel).filter(ContentModel.id == content_id).first()
    if not content:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Content not found"
        )

    db.delete(content)
    db.commit()


@router.get("/analytics")
async def get_analytics(
    days: int = Query(7, ge=1, le=90),
    current_user: UserModel = Depends(require_comms_team),
    db: Session = Depends(get_db),
):
    """Get platform engagement analytics (comms team only)."""
    since = datetime.now(timezone.utc) - timedelta(days=days)

    # Total counts
    total_content = db.query(func.count(ContentModel.id)).scalar()
    total_users = db.query(func.count(UserModel.id)).scalar()

    # Recent activity
    recent_content = (
        db.query(func.count(ContentModel.id))
        .filter(ContentModel.created_at >= since)
        .scalar()
    )
    recent_likes = (
        db.query(func.count(Like.user_id)).filter(Like.created_at >= since).scalar()
    )
    recent_comments = (
        db.query(func.count(Comment.id)).filter(Comment.created_at >= since).scalar()
    )
    recent_views = (
        db.query(func.count(ViewEvent.id))
        .filter(ViewEvent.created_at >= since)
        .scalar()
    )

    # Content by type
    content_by_type = (
        db.query(ContentModel.content_type, func.count(ContentModel.id))
        .group_by(ContentModel.content_type)
        .all()
    )

    # Top content by likes
    top_liked = (
        db.query(
            ContentModel.id,
            ContentModel.title,
            ContentModel.content_type,
            func.count(Like.user_id).label("likes"),
        )
        .join(Like, Like.content_id == ContentModel.id)
        .filter(Like.created_at >= since)
        .group_by(ContentModel.id, ContentModel.title, ContentModel.content_type)
        .order_by(func.count(Like.user_id).desc())
        .limit(10)
        .all()
    )

    # Top content by views
    top_viewed = (
        db.query(
            ContentModel.id,
            ContentModel.title,
            ContentModel.content_type,
            func.count(ViewEvent.id).label("views"),
        )
        .join(ViewEvent, ViewEvent.content_id == ContentModel.id)
        .filter(ViewEvent.created_at >= since)
        .group_by(ContentModel.id, ContentModel.title, ContentModel.content_type)
        .order_by(func.count(ViewEvent.id).desc())
        .limit(10)
        .all()
    )

    # Average completion rate
    avg_completion = (
        db.query(func.avg(ViewEvent.completion_percent))
        .filter(ViewEvent.created_at >= since)
        .scalar()
    ) or 0

    return {
        "period_days": days,
        "totals": {
            "content": total_content,
            "users": total_users,
        },
        "recent_activity": {
            "content_created": recent_content,
            "likes": recent_likes,
            "comments": recent_comments,
            "views": recent_views,
        },
        "content_by_type": {ct: count for ct, count in content_by_type},
        "top_liked": [
            {
                "id": str(c.id),
                "title": c.title,
                "type": c.content_type,
                "likes": c.likes,
            }
            for c in top_liked
        ],
        "top_viewed": [
            {
                "id": str(c.id),
                "title": c.title,
                "type": c.content_type,
                "views": c.views,
            }
            for c in top_viewed
        ],
        "avg_completion_percent": round(avg_completion, 2),
    }


@router.get("/users", response_model=list)
async def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    current_user: UserModel = Depends(require_comms_team),
    db: Session = Depends(get_db),
):
    """List all users (comms team only)."""
    from app.schemas.user import User as UserSchema

    users = (
        db.query(UserModel)
        .order_by(UserModel.display_name)
        .offset(skip)
        .limit(limit)
        .all()
    )
    return [UserSchema.model_validate(u) for u in users]


@router.patch("/users/{user_id}/comms-team")
async def toggle_comms_team(
    user_id: UUID,
    is_comms_team: bool = True,
    current_user: UserModel = Depends(require_comms_team),
    db: Session = Depends(get_db),
):
    """Grant/revoke comms team access (comms team only)."""
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    user.is_comms_team = is_comms_team
    db.commit()

    return {"status": "ok", "user_id": str(user_id), "is_comms_team": is_comms_team}
