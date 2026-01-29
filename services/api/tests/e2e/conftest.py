"""Pytest fixtures for E2E tests."""

import os
import uuid
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session, sessionmaker

from app.db import Base, get_db
from app.main import app
from app.models.content import Content
from app.models.tag import Tag
from app.models.user import User
from app.routers.auth import create_access_token

# Use PostgreSQL test database
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/hackathon",
)

engine = create_engine(TEST_DATABASE_URL)
TestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def generate_unique_id() -> str:
    """Generate a unique ID for test data."""
    return str(uuid.uuid4())[:8]


@pytest.fixture(scope="function")
def db() -> Generator[Session, None, None]:
    """Create a database session for testing."""
    # Ensure tables exist
    Base.metadata.create_all(bind=engine)

    session = TestSessionLocal()
    try:
        yield session
    finally:
        session.rollback()
        session.close()


@pytest.fixture(scope="function")
def api_client(db: Session) -> Generator[TestClient, None, None]:
    """Create a test client with overridden database dependency."""

    def override_get_db():
        try:
            yield db
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


@pytest.fixture(scope="function")
def test_user(db: Session) -> User:
    """Create a test user."""
    unique_id = generate_unique_id()
    user = User(
        email=f"test-{unique_id}@pulsync.io",
        display_name="Test User",
        role="engineering",
        department="Engineering",
    )
    db.add(user)
    db.flush()  # Get the ID without committing
    return user


@pytest.fixture(scope="function")
def second_user(db: Session) -> User:
    """Create a second test user for messaging tests."""
    unique_id = generate_unique_id()
    user = User(
        email=f"other-{unique_id}@pulsync.io",
        display_name="Other User",
        role="marketing",  # Must be a valid UserRole enum value
        department="Marketing",
    )
    db.add(user)
    db.flush()
    return user


@pytest.fixture(scope="function")
def auth_token(test_user: User) -> str:
    """Generate an auth token for the test user."""
    return create_access_token(test_user.id)


@pytest.fixture(scope="function")
def auth_headers(auth_token: str) -> dict:
    """Create auth headers for authenticated requests."""
    return {"Authorization": f"Bearer {auth_token}"}


@pytest.fixture(scope="function")
def authenticated_client(
    api_client: TestClient, auth_headers: dict
) -> tuple[TestClient, dict]:
    """Return client and auth headers together."""
    return api_client, auth_headers


@pytest.fixture(scope="function")
def test_tag(db: Session) -> Tag:
    """Create a test tag."""
    unique_id = generate_unique_id()
    tag = Tag(
        name=f"Test Tag {unique_id}",
        slug=f"test-tag-{unique_id}",
        category="test",
    )
    db.add(tag)
    db.flush()
    return tag


@pytest.fixture(scope="function")
def test_content(db: Session, test_user: User, test_tag: Tag) -> Content:
    """Create test content."""
    content = Content(
        author_id=test_user.id,
        content_type="video",
        title="Test Video",
        body="Test video description",
        media_url="https://example.com/video.mp4",
        thumbnail_url="https://example.com/thumb.jpg",
        duration_seconds=120,
    )
    content.tags.append(test_tag)
    db.add(content)
    db.flush()
    return content


@pytest.fixture(scope="function")
def multiple_content(db: Session, test_user: User, test_tag: Tag) -> list[Content]:
    """Create multiple content items for pagination testing."""
    contents = []
    for i in range(15):
        content = Content(
            author_id=test_user.id,
            content_type="video",
            title=f"Test Video {i}",
            body=f"Test video description {i}",
            media_url=f"https://example.com/video{i}.mp4",
            thumbnail_url=f"https://example.com/thumb{i}.jpg",
            duration_seconds=60 + i * 10,
        )
        content.tags.append(test_tag)
        db.add(content)
        contents.append(content)
    db.flush()
    return contents
