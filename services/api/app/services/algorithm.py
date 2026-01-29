import math
from datetime import datetime, timezone
from uuid import UUID

from app.models.content import Content
from app.models.user import User


def calculate_feed_score(
    content: Content,
    user: User,
    user_interests: dict[UUID, float],
    like_count: int,
    comment_count: int,
) -> float:
    """
    Calculate feed score for content based on the algorithm:

    score = 0
    if company_important: score += 1000
    if role_match: score += 100
    for tag in content.tags:
        score += 50 * user_interest[tag].score
    score *= recency_decay(age_hours)
    score += 10 * sqrt(likes + comments)
    """
    score = 0.0

    # Company important content gets massive boost
    if content.is_company_important:
        score += 1000

    # Role targeting match
    if content.target_roles:
        if user.role in content.target_roles:
            score += 100
    else:
        # No targeting = everyone, small base boost
        score += 50

    # Tag interest scoring
    for tag in content.tags:
        tag_score = user_interests.get(tag.id, 0.0)
        score += 50 * tag_score

    # Recency decay
    age_hours = _get_age_hours(content.created_at)
    recency_multiplier = _recency_decay(age_hours)
    score *= recency_multiplier

    # Engagement boost
    engagement = like_count + comment_count
    score += 10 * math.sqrt(engagement)

    return score


def _get_age_hours(created_at: datetime) -> float:
    """Get content age in hours."""
    now = datetime.now(timezone.utc)
    if created_at.tzinfo is None:
        created_at = created_at.replace(tzinfo=timezone.utc)
    delta = now - created_at
    return delta.total_seconds() / 3600


def _recency_decay(age_hours: float) -> float:
    """
    Calculate recency decay multiplier.
    - Fresh content (< 1 hour): 1.0
    - 24 hours old: ~0.5
    - 1 week old: ~0.1
    - 1 month old: ~0.01
    """
    if age_hours <= 0:
        return 1.0

    # Exponential decay with half-life of 24 hours
    half_life = 24.0
    return math.pow(0.5, age_hours / half_life)
