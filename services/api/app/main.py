from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app.db import Base, engine, get_db
from app.models.item import Item as ItemModel
from app.models.tag import Tag as TagModel
from app.models.user import User as UserModel
from app.routers import (
    admin,
    ai_chat,
    auth,
    comments,
    content,
    feed,
    interactions,
    media,
    messages,
    tags,
)
from app.schemas.item import Item as ItemSchema


def seed_database(db: Session):
    """Seed the database with sample data if empty"""
    # Seed items
    if db.query(ItemModel).count() == 0:
        sample_items = [
            ItemModel(
                name="Widget", description="A useful widget for your desk", price=9.99
            ),
            ItemModel(
                name="Gadget", description="A fancy gadget with buttons", price=19.99
            ),
            ItemModel(
                name="Gizmo",
                description="An amazing gizmo that does things",
                price=29.99,
            ),
        ]
        db.add_all(sample_items)
        db.commit()
        print("Database seeded with sample items")

    # Seed default tags
    if db.query(TagModel).count() == 0:
        default_tags = [
            TagModel(name="Engineering", slug="engineering", category="department"),
            TagModel(name="Product", slug="product", category="department"),
            TagModel(name="Design", slug="design", category="department"),
            TagModel(name="Marketing", slug="marketing", category="department"),
            TagModel(name="HR", slug="hr", category="department"),
            TagModel(name="Company News", slug="company-news", category="topic"),
            TagModel(name="Tech Talks", slug="tech-talks", category="topic"),
            TagModel(name="Culture", slug="culture", category="topic"),
            TagModel(name="Learning", slug="learning", category="topic"),
            TagModel(name="Events", slug="events", category="topic"),
        ]
        db.add_all(default_tags)
        db.commit()
        print("Database seeded with default tags")

    # Seed a demo comms team user
    if (
        db.query(UserModel).filter(UserModel.email == "admin@pulsync.io").first()
        is None
    ):
        admin_user = UserModel(
            email="admin@pulsync.io",
            display_name="Pulsync Admin",
            role="comms",
            department="Communications",
            is_comms_team=True,
        )
        db.add(admin_user)
        db.commit()
        print("Database seeded with admin user")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create tables and seed data
    Base.metadata.create_all(bind=engine)
    db = next(get_db())
    seed_database(db)
    db.close()
    yield
    # Shutdown: cleanup if needed


app = FastAPI(
    title="Pulsync API",
    description="Internal TikTok-style content platform API",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth.router)
app.include_router(content.router)
app.include_router(tags.router)
app.include_router(media.router)
app.include_router(feed.router)
app.include_router(interactions.router)
app.include_router(comments.router)
app.include_router(admin.router)
app.include_router(messages.router)
app.include_router(ai_chat.router)


@app.get("/")
async def root():
    return {"message": "Pulsync API is running!", "docs": "/docs"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.get("/items", response_model=list[ItemSchema])
async def get_items(db: Session = Depends(get_db)):
    """Get all items from the database"""
    return db.query(ItemModel).all()


@app.get("/items/{item_id}", response_model=ItemSchema)
async def get_item(item_id: int, db: Session = Depends(get_db)):
    """Get a specific item by ID"""
    item = db.query(ItemModel).filter(ItemModel.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item
