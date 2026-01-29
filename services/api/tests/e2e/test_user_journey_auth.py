"""E2E tests for authentication user journey."""

import uuid

import pytest
from fastapi.testclient import TestClient


def unique_email(prefix: str = "test") -> str:
    """Generate a unique email for testing."""
    return f"{prefix}-{str(uuid.uuid4())[:8]}@pulsync.io"


class TestAuthFlow:
    """Test the complete authentication flow."""

    def test_login_creates_user(self, api_client: TestClient):
        """Test that login creates a new user if they don't exist."""
        email = unique_email("newuser")
        response = api_client.post(
            "/auth/login",
            json={"token": email},
        )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "user" in data
        assert data["user"]["email"] == email

    def test_login_returns_existing_user(self, api_client: TestClient, test_user):
        """Test that login returns existing user data."""
        response = api_client.post(
            "/auth/login",
            json={"token": test_user.email},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["user"]["email"] == test_user.email
        assert data["user"]["id"] == str(test_user.id)

    def test_get_current_user(self, api_client: TestClient, auth_headers: dict):
        """Test getting current authenticated user."""
        response = api_client.get("/auth/me", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert "email" in data
        assert "display_name" in data

    def test_invalid_token_rejected(self, api_client: TestClient):
        """Test that invalid tokens are rejected."""
        response = api_client.get(
            "/auth/me",
            headers={"Authorization": "Bearer invalid-token"},
        )

        assert response.status_code == 401

    def test_missing_token_rejected(self, api_client: TestClient):
        """Test that missing tokens are rejected."""
        response = api_client.get("/auth/me")

        # HTTPBearer can return 401 or 403 depending on configuration
        assert response.status_code in (401, 403)

    def test_register_new_user(self, api_client: TestClient):
        """Test user registration."""
        email = unique_email("registered")
        response = api_client.post(
            "/auth/register",
            json={
                "email": email,
                "display_name": "Registered User",
                "role": "engineering",
                "department": "Engineering",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["user"]["email"] == email

    def test_register_duplicate_email_fails(self, api_client: TestClient, test_user):
        """Test that registering with existing email fails."""
        response = api_client.post(
            "/auth/register",
            json={
                "email": test_user.email,
                "display_name": "Duplicate User",
                "role": "engineering",
                "department": "Engineering",
            },
        )

        assert response.status_code == 400
        assert "already registered" in response.json()["detail"].lower()


class TestAuthFullJourney:
    """Test complete auth journey scenarios."""

    def test_full_auth_journey(self, api_client: TestClient):
        """Test complete flow: register -> login -> get user."""
        email = unique_email("journey")

        # Step 1: Register
        register_response = api_client.post(
            "/auth/register",
            json={
                "email": email,
                "display_name": "Journey User",
                "role": "engineering",
                "department": "Engineering",
            },
        )
        assert register_response.status_code == 200
        token = register_response.json()["access_token"]

        # Step 2: Login with the same email
        login_response = api_client.post(
            "/auth/login",
            json={"token": email},
        )
        assert login_response.status_code == 200
        login_token = login_response.json()["access_token"]

        # Step 3: Get current user with login token
        me_response = api_client.get(
            "/auth/me",
            headers={"Authorization": f"Bearer {login_token}"},
        )
        assert me_response.status_code == 200
        assert me_response.json()["email"] == email

    def test_token_persistence(self, api_client: TestClient):
        """Test that token remains valid for multiple requests."""
        # Login with unique email
        email = unique_email("persistent")
        login_response = api_client.post(
            "/auth/login",
            json={"token": email},
        )
        token = login_response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Multiple authenticated requests should all succeed
        for _ in range(3):
            response = api_client.get("/auth/me", headers=headers)
            assert response.status_code == 200
