"""E2E tests for feed browsing user journey."""

import pytest
from fastapi.testclient import TestClient

from app.models.content import Content
from app.models.user import User


class TestFeedBrowsing:
    """Test feed browsing functionality."""

    def test_get_feed(self, api_client: TestClient, auth_headers: dict):
        """Test getting feed (may have seeded content)."""
        response = api_client.get("/feed", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "has_more" in data
        # Feed may contain seeded demo content
        assert isinstance(data["items"], list)

    def test_get_feed_with_content(
        self, api_client: TestClient, auth_headers: dict, test_content: Content
    ):
        """Test getting feed with content."""
        response = api_client.get("/feed", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) >= 1

        # Check feed item structure
        item = data["items"][0]
        assert "id" in item
        assert "title" in item
        assert "author" in item
        assert "like_count" in item
        assert "comment_count" in item
        assert "is_liked" in item
        assert "is_bookmarked" in item

    def test_feed_pagination(
        self, api_client: TestClient, auth_headers: dict, multiple_content: list[Content]
    ):
        """Test feed pagination with limit."""
        # Get first page
        response = api_client.get("/feed?limit=5", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()

        assert len(data["items"]) == 5
        assert data["has_more"] is True
        assert data["next_cursor"] is not None

        # Get second page
        cursor = data["next_cursor"]
        response = api_client.get(f"/feed?limit=5&cursor={cursor}", headers=auth_headers)
        assert response.status_code == 200
        data2 = response.json()

        assert len(data2["items"]) == 5
        # Ensure no duplicates
        first_ids = {item["id"] for item in data["items"]}
        second_ids = {item["id"] for item in data2["items"]}
        assert first_ids.isdisjoint(second_ids)

    def test_feed_requires_auth(self, api_client: TestClient):
        """Test that feed requires authentication."""
        response = api_client.get("/feed")
        # HTTPBearer can return 401 or 403 depending on configuration
        assert response.status_code in (401, 403)

    def test_for_you_feed(
        self, api_client: TestClient, auth_headers: dict, test_content: Content
    ):
        """Test the For You feed endpoint."""
        response = api_client.get("/feed/for-you", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert "items" in data

    def test_following_feed_empty(self, api_client: TestClient, auth_headers: dict):
        """Test following feed with no followed tags."""
        response = api_client.get("/feed/following", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert data["items"] == []

    def test_discover_feed(
        self, api_client: TestClient, auth_headers: dict, test_content: Content
    ):
        """Test the discover feed endpoint."""
        response = api_client.get("/feed/discover", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert "items" in data


class TestContentInteractions:
    """Test content interactions from the feed."""

    def test_like_content(
        self, api_client: TestClient, auth_headers: dict, test_content: Content
    ):
        """Test liking content."""
        response = api_client.post(
            f"/content/{test_content.id}/like",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "liked"
        assert data["is_liked"] is True

    def test_unlike_content(
        self, api_client: TestClient, auth_headers: dict, test_content: Content
    ):
        """Test unliking content (toggle)."""
        # Like first
        api_client.post(f"/content/{test_content.id}/like", headers=auth_headers)

        # Unlike (toggle)
        response = api_client.post(
            f"/content/{test_content.id}/like",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "unliked"
        assert data["is_liked"] is False

    def test_bookmark_content(
        self, api_client: TestClient, auth_headers: dict, test_content: Content
    ):
        """Test bookmarking content."""
        response = api_client.post(
            f"/content/{test_content.id}/bookmark",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "bookmarked"
        assert data["is_bookmarked"] is True

    def test_unbookmark_content(
        self, api_client: TestClient, auth_headers: dict, test_content: Content
    ):
        """Test unbookmarking content (toggle)."""
        # Bookmark first
        api_client.post(f"/content/{test_content.id}/bookmark", headers=auth_headers)

        # Unbookmark (toggle)
        response = api_client.post(
            f"/content/{test_content.id}/bookmark",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "unbookmarked"
        assert data["is_bookmarked"] is False

    def test_get_bookmarks(
        self, api_client: TestClient, auth_headers: dict, test_content: Content
    ):
        """Test getting user's bookmarks."""
        # Bookmark content first
        api_client.post(f"/content/{test_content.id}/bookmark", headers=auth_headers)

        response = api_client.get("/bookmarks", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["id"] == str(test_content.id)

    def test_get_likes(
        self, api_client: TestClient, auth_headers: dict, test_content: Content
    ):
        """Test getting user's liked content."""
        # Like content first
        api_client.post(f"/content/{test_content.id}/like", headers=auth_headers)

        response = api_client.get("/likes", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["id"] == str(test_content.id)

    def test_like_nonexistent_content(self, api_client: TestClient, auth_headers: dict):
        """Test liking nonexistent content returns 404."""
        import uuid

        fake_id = uuid.uuid4()
        response = api_client.post(
            f"/content/{fake_id}/like",
            headers=auth_headers,
        )

        assert response.status_code == 404


class TestFeedFullJourney:
    """Test complete feed browsing journey."""

    def test_browse_and_interact_journey(
        self, api_client: TestClient, auth_headers: dict, multiple_content: list[Content]
    ):
        """Test complete journey: browse feed -> like -> bookmark -> view bookmarks."""
        # Step 1: Browse feed
        feed_response = api_client.get("/feed?limit=10", headers=auth_headers)
        assert feed_response.status_code == 200
        items = feed_response.json()["items"]
        assert len(items) > 0

        content_id = items[0]["id"]

        # Step 2: Like first item
        like_response = api_client.post(
            f"/content/{content_id}/like",
            headers=auth_headers,
        )
        assert like_response.status_code == 200
        assert like_response.json()["is_liked"] is True

        # Step 3: Bookmark first item
        bookmark_response = api_client.post(
            f"/content/{content_id}/bookmark",
            headers=auth_headers,
        )
        assert bookmark_response.status_code == 200
        assert bookmark_response.json()["is_bookmarked"] is True

        # Step 4: Verify in bookmarks
        bookmarks_response = api_client.get("/bookmarks", headers=auth_headers)
        assert bookmarks_response.status_code == 200
        bookmarks = bookmarks_response.json()
        assert any(b["id"] == content_id for b in bookmarks)

        # Step 5: Verify in likes
        likes_response = api_client.get("/likes", headers=auth_headers)
        assert likes_response.status_code == 200
        likes = likes_response.json()
        assert any(like["id"] == content_id for like in likes)

        # Step 6: Verify feed shows is_liked and is_bookmarked
        feed_again = api_client.get("/feed?limit=10", headers=auth_headers)
        items = feed_again.json()["items"]
        interacted_item = next((i for i in items if i["id"] == content_id), None)
        assert interacted_item is not None
        assert interacted_item["is_liked"] is True
        assert interacted_item["is_bookmarked"] is True
