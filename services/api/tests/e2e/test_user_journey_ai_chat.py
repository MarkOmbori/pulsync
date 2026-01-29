"""E2E tests for AI chat user journey."""

import json
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.models.user import User


class TestAIChatSessions:
    """Test AI chat session management."""

    def test_list_sessions_empty(self, api_client: TestClient, auth_headers: dict):
        """Test listing sessions when empty."""
        response = api_client.get("/ai-chat/sessions", headers=auth_headers)

        assert response.status_code == 200
        assert response.json() == []

    def test_create_session(self, api_client: TestClient, auth_headers: dict):
        """Test creating a new AI chat session."""
        response = api_client.post(
            "/ai-chat/sessions",
            headers=auth_headers,
            json={"title": "Test Session"},
        )

        assert response.status_code == 201
        data = response.json()
        assert "id" in data
        assert data["title"] == "Test Session"

    def test_create_session_without_title(
        self, api_client: TestClient, auth_headers: dict
    ):
        """Test creating a session without a title."""
        response = api_client.post(
            "/ai-chat/sessions",
            headers=auth_headers,
            json={},
        )

        assert response.status_code == 201
        data = response.json()
        assert data["title"] is None

    def test_get_session(self, api_client: TestClient, auth_headers: dict):
        """Test getting a session with messages."""
        # Create session
        create_response = api_client.post(
            "/ai-chat/sessions",
            headers=auth_headers,
            json={"title": "Test Session"},
        )
        session_id = create_response.json()["id"]

        # Get session
        response = api_client.get(
            f"/ai-chat/sessions/{session_id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == session_id
        assert "messages" in data
        assert data["messages"] == []

    def test_get_nonexistent_session(self, api_client: TestClient, auth_headers: dict):
        """Test getting a session that doesn't exist."""
        import uuid

        fake_id = uuid.uuid4()
        response = api_client.get(
            f"/ai-chat/sessions/{fake_id}",
            headers=auth_headers,
        )

        assert response.status_code == 404

    def test_delete_session(self, api_client: TestClient, auth_headers: dict):
        """Test deleting a session."""
        # Create session
        create_response = api_client.post(
            "/ai-chat/sessions",
            headers=auth_headers,
            json={"title": "To Delete"},
        )
        session_id = create_response.json()["id"]

        # Delete session
        response = api_client.delete(
            f"/ai-chat/sessions/{session_id}",
            headers=auth_headers,
        )

        assert response.status_code == 204

        # Verify deleted
        get_response = api_client.get(
            f"/ai-chat/sessions/{session_id}",
            headers=auth_headers,
        )
        assert get_response.status_code == 404

    def test_list_sessions_paginated(self, api_client: TestClient, auth_headers: dict):
        """Test paginated session listing."""
        # Create multiple sessions
        for i in range(5):
            api_client.post(
                "/ai-chat/sessions",
                headers=auth_headers,
                json={"title": f"Session {i}"},
            )

        # Get paginated list
        response = api_client.get(
            "/ai-chat/sessions?limit=3",
            headers=auth_headers,
        )

        assert response.status_code == 200
        sessions = response.json()
        assert len(sessions) == 3


class TestAIChatMessages:
    """Test AI chat messaging."""

    def test_send_message_streams_response(
        self, api_client: TestClient, auth_headers: dict
    ):
        """Test sending a message and receiving a streaming response."""
        # Create session
        create_response = api_client.post(
            "/ai-chat/sessions",
            headers=auth_headers,
            json={"title": "Chat Session"},
        )
        session_id = create_response.json()["id"]

        # Mock the AI service to return predictable response
        async def mock_stream(*args, **kwargs):
            yield "Hello"
            yield " there"
            yield "!"

        with patch(
            "app.routers.ai_chat.stream_ai_response",
            return_value=mock_stream(),
        ):
            # Send message (this uses SSE streaming)
            response = api_client.post(
                f"/ai-chat/sessions/{session_id}/messages",
                headers=auth_headers,
                json={"content": "Hi, how are you?"},
            )

            assert response.status_code == 200
            # SSE response should have text/event-stream content type
            assert "text/event-stream" in response.headers.get("content-type", "")

    def test_send_message_to_nonexistent_session(
        self, api_client: TestClient, auth_headers: dict
    ):
        """Test sending a message to a session that doesn't exist."""
        import uuid

        fake_id = uuid.uuid4()
        response = api_client.post(
            f"/ai-chat/sessions/{fake_id}/messages",
            headers=auth_headers,
            json={"content": "Hello"},
        )

        assert response.status_code == 404

    def test_session_title_auto_generated(
        self, api_client: TestClient, auth_headers: dict
    ):
        """Test that session title is auto-generated from first message."""
        # Create session without title
        create_response = api_client.post(
            "/ai-chat/sessions",
            headers=auth_headers,
            json={},
        )
        session_id = create_response.json()["id"]
        assert create_response.json()["title"] is None

        # Mock the AI service
        async def mock_stream(*args, **kwargs):
            yield "Response"

        with patch(
            "app.routers.ai_chat.stream_ai_response",
            return_value=mock_stream(),
        ):
            # Send first message
            api_client.post(
                f"/ai-chat/sessions/{session_id}/messages",
                headers=auth_headers,
                json={"content": "What is the meaning of life?"},
            )

        # Check session now has a title
        get_response = api_client.get(
            f"/ai-chat/sessions/{session_id}",
            headers=auth_headers,
        )
        # Title should be set (by generate_session_title)
        assert get_response.json()["title"] is not None


class TestAIChatFullJourney:
    """Test complete AI chat journey."""

    def test_complete_ai_chat_flow(self, api_client: TestClient, auth_headers: dict):
        """Test complete flow: create session -> send message -> receive response -> view history."""
        # Step 1: List sessions (empty)
        list_response = api_client.get("/ai-chat/sessions", headers=auth_headers)
        assert list_response.status_code == 200
        assert len(list_response.json()) == 0

        # Step 2: Create session
        create_response = api_client.post(
            "/ai-chat/sessions",
            headers=auth_headers,
            json={"title": "My Chat"},
        )
        assert create_response.status_code == 201
        session_id = create_response.json()["id"]

        # Step 3: Send message (mock AI response)
        async def mock_stream(*args, **kwargs):
            yield "I'm"
            yield " doing"
            yield " well"
            yield "!"

        with patch(
            "app.routers.ai_chat.stream_ai_response",
            return_value=mock_stream(),
        ):
            message_response = api_client.post(
                f"/ai-chat/sessions/{session_id}/messages",
                headers=auth_headers,
                json={"content": "How are you?"},
            )
            assert message_response.status_code == 200

            # Consume the streaming response
            content = message_response.text
            assert "event" in content  # SSE format

        # Step 4: View session history
        get_response = api_client.get(
            f"/ai-chat/sessions/{session_id}",
            headers=auth_headers,
        )
        assert get_response.status_code == 200
        session = get_response.json()
        # Should have at least the user message
        assert len(session["messages"]) >= 1
        assert session["messages"][0]["role"] == "user"
        assert session["messages"][0]["content"] == "How are you?"

        # Step 5: Verify session appears in list
        list_response2 = api_client.get("/ai-chat/sessions", headers=auth_headers)
        assert list_response2.status_code == 200
        sessions = list_response2.json()
        assert len(sessions) == 1
        assert sessions[0]["id"] == session_id

    def test_multiple_sessions_isolated(
        self, api_client: TestClient, auth_headers: dict
    ):
        """Test that multiple sessions are isolated from each other."""
        # Create two sessions
        session1 = api_client.post(
            "/ai-chat/sessions",
            headers=auth_headers,
            json={"title": "Session 1"},
        ).json()

        session2 = api_client.post(
            "/ai-chat/sessions",
            headers=auth_headers,
            json={"title": "Session 2"},
        ).json()

        # Mock AI response
        async def mock_stream(*args, **kwargs):
            yield "Response"

        with patch(
            "app.routers.ai_chat.stream_ai_response",
            return_value=mock_stream(),
        ):
            # Send message to session 1
            api_client.post(
                f"/ai-chat/sessions/{session1['id']}/messages",
                headers=auth_headers,
                json={"content": "Message for session 1"},
            )

        # Session 2 should still be empty
        get_session2 = api_client.get(
            f"/ai-chat/sessions/{session2['id']}",
            headers=auth_headers,
        )
        assert get_session2.json()["messages"] == []


class TestAIChatAuth:
    """Test AI chat authentication requirements."""

    def test_sessions_require_auth(self, api_client: TestClient):
        """Test that session endpoints require authentication."""
        response = api_client.get("/ai-chat/sessions")
        # HTTPBearer can return 401 or 403 depending on configuration
        assert response.status_code in (401, 403)

    def test_cannot_access_other_user_session(
        self,
        api_client: TestClient,
        auth_headers: dict,
        second_user: User,
    ):
        """Test that users cannot access other users' sessions."""
        from app.routers.auth import create_access_token

        # Create session as test_user
        create_response = api_client.post(
            "/ai-chat/sessions",
            headers=auth_headers,
            json={"title": "Private Session"},
        )
        session_id = create_response.json()["id"]

        # Try to access as second_user
        other_token = create_access_token(second_user.id)
        other_headers = {"Authorization": f"Bearer {other_token}"}

        response = api_client.get(
            f"/ai-chat/sessions/{session_id}",
            headers=other_headers,
        )

        assert response.status_code == 404
