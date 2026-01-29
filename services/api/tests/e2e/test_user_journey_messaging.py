"""E2E tests for messaging user journey."""

import pytest
from fastapi.testclient import TestClient

from app.models.user import User
from app.routers.auth import create_access_token


class TestConversations:
    """Test conversation management."""

    def test_list_conversations_empty(self, api_client: TestClient, auth_headers: dict):
        """Test listing conversations when empty."""
        response = api_client.get("/messages/conversations", headers=auth_headers)

        assert response.status_code == 200
        assert response.json() == []

    def test_create_conversation(
        self,
        api_client: TestClient,
        auth_headers: dict,
        test_user: User,
        second_user: User,
    ):
        """Test creating a new conversation."""
        response = api_client.post(
            "/messages/conversations",
            headers=auth_headers,
            json={
                "participant_ids": [str(second_user.id)],
                "initial_message": "Hello!",
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert "id" in data
        assert len(data["participants"]) == 2
        assert data["last_message"]["body"] == "Hello!"

    def test_create_conversation_requires_participant(
        self, api_client: TestClient, auth_headers: dict, test_user: User
    ):
        """Test that creating a conversation requires at least one other participant."""
        response = api_client.post(
            "/messages/conversations",
            headers=auth_headers,
            json={"participant_ids": []},
        )

        assert response.status_code == 400

    def test_create_conversation_idempotent(
        self,
        api_client: TestClient,
        auth_headers: dict,
        test_user: User,
        second_user: User,
    ):
        """Test that creating same 1:1 conversation returns existing one."""
        # Create first conversation
        response1 = api_client.post(
            "/messages/conversations",
            headers=auth_headers,
            json={"participant_ids": [str(second_user.id)]},
        )
        assert response1.status_code == 201
        conv_id1 = response1.json()["id"]

        # Try to create same conversation
        response2 = api_client.post(
            "/messages/conversations",
            headers=auth_headers,
            json={"participant_ids": [str(second_user.id)]},
        )
        assert response2.status_code == 201
        conv_id2 = response2.json()["id"]

        assert conv_id1 == conv_id2

    def test_get_conversation(
        self,
        api_client: TestClient,
        auth_headers: dict,
        test_user: User,
        second_user: User,
    ):
        """Test getting a conversation with messages."""
        # Create conversation with message
        create_response = api_client.post(
            "/messages/conversations",
            headers=auth_headers,
            json={
                "participant_ids": [str(second_user.id)],
                "initial_message": "Hello there!",
            },
        )
        conv_id = create_response.json()["id"]

        # Get conversation
        response = api_client.get(
            f"/messages/conversations/{conv_id}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == conv_id
        assert "messages" in data
        assert len(data["messages"]) == 1
        assert data["messages"][0]["body"] == "Hello there!"

    def test_get_nonexistent_conversation(
        self, api_client: TestClient, auth_headers: dict
    ):
        """Test getting a conversation that doesn't exist."""
        import uuid

        fake_id = uuid.uuid4()
        response = api_client.get(
            f"/messages/conversations/{fake_id}",
            headers=auth_headers,
        )

        assert response.status_code == 404


class TestMessages:
    """Test message sending and retrieval."""

    def test_send_message(
        self,
        api_client: TestClient,
        auth_headers: dict,
        test_user: User,
        second_user: User,
    ):
        """Test sending a message to a conversation."""
        # Create conversation
        create_response = api_client.post(
            "/messages/conversations",
            headers=auth_headers,
            json={"participant_ids": [str(second_user.id)]},
        )
        conv_id = create_response.json()["id"]

        # Send message
        response = api_client.post(
            f"/messages/conversations/{conv_id}/messages",
            headers=auth_headers,
            json={"body": "Test message"},
        )

        assert response.status_code == 201
        data = response.json()
        assert data["body"] == "Test message"
        assert data["sender_id"] == str(test_user.id)

    def test_get_messages_paginated(
        self,
        api_client: TestClient,
        auth_headers: dict,
        test_user: User,
        second_user: User,
    ):
        """Test getting paginated messages."""
        # Create conversation
        create_response = api_client.post(
            "/messages/conversations",
            headers=auth_headers,
            json={"participant_ids": [str(second_user.id)]},
        )
        conv_id = create_response.json()["id"]

        # Send multiple messages
        for i in range(10):
            api_client.post(
                f"/messages/conversations/{conv_id}/messages",
                headers=auth_headers,
                json={"body": f"Message {i}"},
            )

        # Get messages with limit
        response = api_client.get(
            f"/messages/conversations/{conv_id}/messages?limit=5",
            headers=auth_headers,
        )

        assert response.status_code == 200
        messages = response.json()
        assert len(messages) == 5

    def test_send_message_to_nonexistent_conversation(
        self, api_client: TestClient, auth_headers: dict
    ):
        """Test sending a message to a conversation that doesn't exist."""
        import uuid

        fake_id = uuid.uuid4()
        response = api_client.post(
            f"/messages/conversations/{fake_id}/messages",
            headers=auth_headers,
            json={"body": "Test"},
        )

        assert response.status_code == 404


class TestUserSearch:
    """Test user search for messaging."""

    def test_search_users(
        self,
        api_client: TestClient,
        auth_headers: dict,
        second_user: User,
    ):
        """Test searching for users to message."""
        # Search by unique email to avoid matching stale data from previous runs
        search_term = second_user.email.split("@")[0]  # e.g., "other-abc123"
        response = api_client.get(
            f"/messages/users/search?q={search_term}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        users = response.json()
        assert len(users) >= 1
        assert any(u["id"] == str(second_user.id) for u in users)

    def test_search_excludes_current_user(
        self,
        api_client: TestClient,
        auth_headers: dict,
        test_user: User,
    ):
        """Test that search excludes the current user."""
        response = api_client.get(
            f"/messages/users/search?q={test_user.display_name}",
            headers=auth_headers,
        )

        assert response.status_code == 200
        users = response.json()
        assert not any(u["id"] == str(test_user.id) for u in users)


class TestMessagingFullJourney:
    """Test complete messaging journey."""

    def test_complete_dm_flow(
        self,
        api_client: TestClient,
        auth_headers: dict,
        test_user: User,
        second_user: User,
        db,
    ):
        """Test complete DM flow: search -> create conversation -> send messages -> load history."""
        # Step 1: Search for user to message (use unique email prefix to avoid stale data)
        search_term = second_user.email.split("@")[0]
        search_response = api_client.get(
            f"/messages/users/search?q={search_term}",
            headers=auth_headers,
        )
        assert search_response.status_code == 200
        users = search_response.json()
        target_user = next((u for u in users if u["id"] == str(second_user.id)), None)
        assert target_user is not None

        # Step 2: Create conversation
        create_response = api_client.post(
            "/messages/conversations",
            headers=auth_headers,
            json={
                "participant_ids": [target_user["id"]],
                "initial_message": "Hey, how are you?",
            },
        )
        assert create_response.status_code == 201
        conv_id = create_response.json()["id"]

        # Step 3: Send more messages
        for msg in ["I wanted to ask about the project", "Are you free to chat?"]:
            response = api_client.post(
                f"/messages/conversations/{conv_id}/messages",
                headers=auth_headers,
                json={"body": msg},
            )
            assert response.status_code == 201

        # Step 4: Load message history
        messages_response = api_client.get(
            f"/messages/conversations/{conv_id}/messages",
            headers=auth_headers,
        )
        assert messages_response.status_code == 200
        messages = messages_response.json()
        assert len(messages) == 3

        # Step 5: Verify conversation shows in list
        list_response = api_client.get("/messages/conversations", headers=auth_headers)
        assert list_response.status_code == 200
        conversations = list_response.json()
        assert any(c["id"] == conv_id for c in conversations)

        # Step 6: Other user can see the conversation
        other_token = create_access_token(second_user.id)
        other_headers = {"Authorization": f"Bearer {other_token}"}

        other_list = api_client.get("/messages/conversations", headers=other_headers)
        assert other_list.status_code == 200
        other_convs = other_list.json()
        assert any(c["id"] == conv_id for c in other_convs)

    def test_leave_conversation(
        self,
        api_client: TestClient,
        auth_headers: dict,
        test_user: User,
        second_user: User,
    ):
        """Test leaving a conversation."""
        # Create conversation
        create_response = api_client.post(
            "/messages/conversations",
            headers=auth_headers,
            json={"participant_ids": [str(second_user.id)]},
        )
        conv_id = create_response.json()["id"]

        # Leave conversation
        response = api_client.delete(
            f"/messages/conversations/{conv_id}",
            headers=auth_headers,
        )

        assert response.status_code == 204

        # Verify conversation no longer accessible
        get_response = api_client.get(
            f"/messages/conversations/{conv_id}",
            headers=auth_headers,
        )
        assert get_response.status_code == 404
