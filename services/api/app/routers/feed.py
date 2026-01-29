from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.db import get_db
from app.models.bookmark import Bookmark
from app.models.comment import Comment
from app.models.content import Content as ContentModel
from app.models.like import Like
from app.models.tag import Tag as TagModel
from app.models.user import User as UserModel
from app.models.user_interest import UserInterest
from app.models.view_event import ViewEvent as ViewEventModel
from app.routers.auth import get_current_user
from app.schemas.content import ContentFeedItem
from app.schemas.feed import FeedResponse, FollowTagRequest
from app.schemas.feed import UserInterest as UserInterestSchema
from app.schemas.view_event import ViewEventCreate
from app.services.algorithm import calculate_feed_score

router = APIRouter(prefix="/feed", tags=["feed"])


def build_feed_item(
    content: ContentModel, current_user: UserModel, db: Session
) -> ContentFeedItem:
    """Build a ContentFeedItem with engagement stats."""
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
    is_bookmarked = (
        db.query(Bookmark)
        .filter(Bookmark.content_id == content.id, Bookmark.user_id == current_user.id)
        .first()
        is not None
    )

    return ContentFeedItem(
        id=content.id,
        author=content.author,
        content_type=content.content_type,
        title=content.title,
        body=content.body,
        media_url=content.media_url,
        thumbnail_url=content.thumbnail_url,
        duration_seconds=content.duration_seconds,
        is_company_important=content.is_company_important,
        tags=content.tags,
        like_count=like_count,
        comment_count=comment_count,
        is_liked=is_liked,
        is_bookmarked=is_bookmarked,
        created_at=content.created_at,
    )


@router.get("", response_model=FeedResponse)
async def get_feed(
    cursor: str | None = None,
    limit: int = Query(10, ge=1, le=50),
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get personalized content feed (For You)."""
    # Get user interests
    interests = (
        db.query(UserInterest).filter(UserInterest.user_id == current_user.id).all()
    )
    interest_map = {i.tag_id: i.score for i in interests}

    # Get content with author and tags
    query = db.query(ContentModel).options(
        joinedload(ContentModel.author), joinedload(ContentModel.tags)
    )

    # Filter by target roles if set
    query = query.filter(
        (ContentModel.target_roles.is_(None))
        | (ContentModel.target_roles.contains([current_user.role]))
    )

    contents = query.all()

    # Score and sort content
    scored_contents = []
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
        score = calculate_feed_score(
            content, current_user, interest_map, like_count, comment_count
        )
        scored_contents.append((score, content))

    scored_contents.sort(key=lambda x: x[0], reverse=True)

    # Handle cursor pagination
    start_idx = 0
    if cursor:
        for idx, (_, c) in enumerate(scored_contents):
            if str(c.id) == cursor:
                start_idx = idx + 1
                break

    paginated = scored_contents[start_idx : start_idx + limit]
    has_more = start_idx + limit < len(scored_contents)
    next_cursor = str(paginated[-1][1].id) if paginated and has_more else None

    items = [build_feed_item(content, current_user, db) for _, content in paginated]

    return FeedResponse(items=items, next_cursor=next_cursor, has_more=has_more)


@router.get("/for-you", response_model=FeedResponse)
async def get_for_you_feed(
    cursor: str | None = None,
    limit: int = Query(10, ge=1, le=50),
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Alias for /feed - personalized recommendations."""
    return await get_feed(cursor=cursor, limit=limit, current_user=current_user, db=db)


@router.get("/following", response_model=FeedResponse)
async def get_following_feed(
    cursor: str | None = None,
    limit: int = Query(10, ge=1, le=50),
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get content from followed tags."""
    # Get followed tags
    followed = (
        db.query(UserInterest)
        .filter(
            UserInterest.user_id == current_user.id,
            (UserInterest.is_manually_followed.is_(True))
            | (UserInterest.is_auto_subscribed.is_(True)),
        )
        .all()
    )
    followed_tag_ids = [f.tag_id for f in followed]

    if not followed_tag_ids:
        return FeedResponse(items=[], next_cursor=None, has_more=False)

    # Get content with those tags
    query = (
        db.query(ContentModel)
        .options(joinedload(ContentModel.author), joinedload(ContentModel.tags))
        .join(ContentModel.tags)
        .filter(TagModel.id.in_(followed_tag_ids))
        .order_by(ContentModel.created_at.desc())
        .distinct()
    )

    # Cursor pagination
    if cursor:
        cursor_content = (
            db.query(ContentModel).filter(ContentModel.id == cursor).first()
        )
        if cursor_content:
            query = query.filter(ContentModel.created_at < cursor_content.created_at)

    contents = query.limit(limit + 1).all()
    has_more = len(contents) > limit
    contents = contents[:limit]

    next_cursor = str(contents[-1].id) if contents and has_more else None
    items = [build_feed_item(c, current_user, db) for c in contents]

    return FeedResponse(items=items, next_cursor=next_cursor, has_more=has_more)


@router.get("/discover", response_model=FeedResponse)
async def get_discover_feed(
    cursor: str | None = None,
    limit: int = Query(10, ge=1, le=50),
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get content outside user's typical interests."""
    # Get user's high-interest tags
    high_interest = (
        db.query(UserInterest)
        .filter(UserInterest.user_id == current_user.id, UserInterest.score > 0.5)
        .all()
    )
    exclude_tag_ids = [i.tag_id for i in high_interest]

    query = db.query(ContentModel).options(
        joinedload(ContentModel.author), joinedload(ContentModel.tags)
    )

    if exclude_tag_ids:
        # Exclude content that has the user's high-interest tags
        query = query.filter(~ContentModel.tags.any(TagModel.id.in_(exclude_tag_ids)))

    query = query.order_by(ContentModel.created_at.desc())

    if cursor:
        cursor_content = (
            db.query(ContentModel).filter(ContentModel.id == cursor).first()
        )
        if cursor_content:
            query = query.filter(ContentModel.created_at < cursor_content.created_at)

    contents = query.limit(limit + 1).all()
    has_more = len(contents) > limit
    contents = contents[:limit]

    next_cursor = str(contents[-1].id) if contents and has_more else None
    items = [build_feed_item(c, current_user, db) for c in contents]

    return FeedResponse(items=items, next_cursor=next_cursor, has_more=has_more)


@router.post("/view")
async def record_view(
    view_data: ViewEventCreate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Record a view event for content."""
    view = ViewEventModel(
        user_id=current_user.id,
        content_id=view_data.content_id,
        view_duration_seconds=view_data.view_duration_seconds,
        completion_percent=view_data.completion_percent,
    )
    db.add(view)

    # Update user interests based on view
    content = (
        db.query(ContentModel)
        .options(joinedload(ContentModel.tags))
        .filter(ContentModel.id == view_data.content_id)
        .first()
    )
    if content and content.tags:
        for tag in content.tags:
            interest = (
                db.query(UserInterest)
                .filter(
                    UserInterest.user_id == current_user.id,
                    UserInterest.tag_id == tag.id,
                )
                .first()
            )
            if not interest:
                interest = UserInterest(
                    user_id=current_user.id, tag_id=tag.id, score=0.0
                )
                db.add(interest)

            # Increase score based on completion (max +0.1 per view)
            score_increase = min(view_data.completion_percent / 100.0, 1.0) * 0.1
            interest.score = min(interest.score + score_increase, 1.0)

            # Auto-subscribe if score crosses threshold
            if interest.score > 0.7 and not interest.is_auto_subscribed:
                interest.is_auto_subscribed = True

    db.commit()
    return {"status": "ok"}


@router.get("/interests", response_model=list[UserInterestSchema])
async def get_interests(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get user's tag interests."""
    return db.query(UserInterest).filter(UserInterest.user_id == current_user.id).all()


@router.post("/interests/{tag_id}/follow")
async def follow_tag(
    tag_id: UUID,
    request: FollowTagRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Manually follow/unfollow a tag."""
    interest = (
        db.query(UserInterest)
        .filter(UserInterest.user_id == current_user.id, UserInterest.tag_id == tag_id)
        .first()
    )

    if not interest:
        interest = UserInterest(
            user_id=current_user.id,
            tag_id=tag_id,
            score=0.5,
            is_manually_followed=request.follow,
        )
        db.add(interest)
    else:
        interest.is_manually_followed = request.follow

    db.commit()
    return {"status": "ok", "is_following": request.follow}
