import pytest


@pytest.mark.blackbox
def test_registration_login_and_profile_flow(client):
    weak = client.post(
        "/auth/register", json={"email": "me@example.com", "password": "short"}
    )
    assert weak.status_code == 422

    registered = client.post(
        "/auth/register",
        json={"email": "ME@example.com", "password": "correct-horse"},
    )
    assert registered.status_code == 200
    assert registered.json()["email"] == "me@example.com"
    assert "hashed_password" not in registered.json()

    duplicate = client.post(
        "/auth/register",
        json={"email": "me@example.com", "password": "correct-horse"},
    )
    assert duplicate.status_code == 409
    login = client.post(
        "/auth/login",
        data={"username": "me@example.com", "password": "correct-horse"},
    )
    assert login.status_code == 200
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

    updated = client.patch(
        "/auth/me",
        headers=headers,
        json={
            "display_name": "Dress Tester",
            "style_preferences": "minimal, neutral",
            "location_name": "Kathmandu",
            "latitude": 27.7172,
            "longitude": 85.324,
        },
    )
    assert updated.status_code == 200
    assert updated.json()["display_name"] == "Dress Tester"
    assert (
        client.get("/auth/me", headers=headers).json()["location_name"] == "Kathmandu"
    )


@pytest.mark.blackbox
def test_protected_endpoint_rejects_invalid_token(client):
    response = client.get(
        "/items/", headers={"Authorization": "Bearer definitely-not-a-token"}
    )
    assert response.status_code == 401
