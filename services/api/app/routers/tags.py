from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.models.tag import Tag as TagModel
from app.models.user import User as UserModel
from app.routers.auth import get_current_user
from app.schemas.tag import Tag, TagCreate, TagUpdate

router = APIRouter(prefix="/tags", tags=["tags"])


@router.get("", response_model=list[Tag])
async def list_tags(db: Session = Depends(get_db)):
    """List all tags."""
    return db.query(TagModel).order_by(TagModel.name).all()


@router.post("", response_model=Tag, status_code=status.HTTP_201_CREATED)
async def create_tag(
    tag_data: TagCreate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new tag (comms team only)."""
    if not current_user.is_comms_team:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only comms team can create tags",
        )

    existing = db.query(TagModel).filter(TagModel.slug == tag_data.slug).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Tag slug already exists"
        )

    tag = TagModel(**tag_data.model_dump())
    db.add(tag)
    db.commit()
    db.refresh(tag)
    return tag


@router.get("/{tag_id}", response_model=Tag)
async def get_tag(tag_id: UUID, db: Session = Depends(get_db)):
    """Get a specific tag."""
    tag = db.query(TagModel).filter(TagModel.id == tag_id).first()
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Tag not found"
        )
    return tag


@router.patch("/{tag_id}", response_model=Tag)
async def update_tag(
    tag_id: UUID,
    tag_data: TagUpdate,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update a tag (comms team only)."""
    if not current_user.is_comms_team:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only comms team can update tags",
        )

    tag = db.query(TagModel).filter(TagModel.id == tag_id).first()
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Tag not found"
        )

    update_data = tag_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(tag, key, value)

    db.commit()
    db.refresh(tag)
    return tag


@router.delete("/{tag_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tag(
    tag_id: UUID,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a tag (comms team only)."""
    if not current_user.is_comms_team:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only comms team can delete tags",
        )

    tag = db.query(TagModel).filter(TagModel.id == tag_id).first()
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Tag not found"
        )

    db.delete(tag)
    db.commit()
