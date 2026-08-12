from unittest.mock import AsyncMock

import pytest

import schemas
from ai_service import get_outfit_recommendation


@pytest.mark.blackbox
def test_recommendation_and_saved_outfit_flow(client, account, wardrobe_item, mocker):
    owner = account()
    item = wardrobe_item(owner)
    generated = schemas.AIRecommendation(
        title="Clean casual look",
        items=[
            schemas.AIRecommendationItem(
                clothing_item_id=item["id"], reason="A versatile base layer."
            )
        ],
        explanation=["Balanced for the occasion."],
        confidence_score=0.9,
    )
    mocker.patch(
        "routers.recommendation.get_outfit_recommendation",
        new=AsyncMock(
            return_value={
                "recommendation": generated,
                "provider": "gemini",
                "model": "test-model",
            }
        ),
    )

    response = client.post(
        "/recommendations",
        headers=owner["headers"],
        json={
            "occasion": "casual",
            "manual_weather": "mild and dry",
            "use_live_weather": False,
        },
    )
    assert response.status_code == 200, response.text
    result = response.json()
    assert result["items"][0]["clothing_item_id"] == item["id"]
    assert result["provider"] == "gemini"

    saved = client.post(
        "/outfits/save",
        headers=owner["headers"],
        json={
            "title": result["title"],
            "occasion": result["occasion"],
            "weather": result["weather_summary"],
            "recommendation_text": " ".join(result["explanation"]),
            "item_ids": [item["id"]],
            "reasons": {str(item["id"]): result["items"][0]["reason"]},
            "provider": result["provider"],
            "model_used": result["model_used"],
            "confidence_score": result["confidence_score"],
        },
    )
    assert saved.status_code == 200, saved.text
    assert saved.json()["items"][0]["item"]["name"] == "Navy shirt"
    assert len(client.get("/outfits/", headers=owner["headers"]).json()) == 1


@pytest.mark.blackbox
def test_friend_feedback_notifications_and_wardrobe_share(
    client, account, wardrobe_item
):
    owner = account()
    friend = account("friend@example.com")
    stranger = account("third@example.com")
    item = wardrobe_item(owner)

    requested = client.post(
        "/friends/request",
        headers=owner["headers"],
        json={"addressee_email": friend["email"]},
    )
    assert requested.status_code == 200
    friendship_id = requested.json()["id"]
    accepted = client.post(
        f"/friends/accept/{friendship_id}", headers=friend["headers"]
    )
    assert accepted.status_code == 200
    assert accepted.json()["friend_user_id"] == owner["id"]

    shared = client.post(
        "/wardrobe-shares",
        headers=owner["headers"],
        json={"friend_user_id": friend["id"], "item_ids": [item["id"]]},
    )
    assert shared.status_code == 200, shared.text
    share_id = shared.json()["id"]
    visible = client.get(
        f"/wardrobe-shares/{share_id}/items", headers=friend["headers"]
    )
    assert [row["id"] for row in visible.json()] == [item["id"]]
    forbidden = client.get(
        f"/wardrobe-shares/{share_id}/items", headers=stranger["headers"]
    )
    assert forbidden.status_code == 403
    assert client.get(item["image_url"], headers=friend["headers"]).status_code == 200

    feedback = client.post(
        "/feedback/requests",
        headers=owner["headers"],
        json={
            "recipient_id": friend["id"],
            "item_ids": [item["id"]],
            "message": "Does this work?",
        },
    )
    assert feedback.status_code == 200, feedback.text
    responded = client.post(
        f"/feedback/requests/{feedback.json()['id']}/respond",
        headers=friend["headers"],
        json={"rating": 5, "comment": "Looks great."},
    )
    assert responded.status_code == 200
    assert responded.json()["status"] == "responded"

    notifications = client.get("/notifications", headers=owner["headers"])
    assert notifications.status_code == 200
    assert any(row["type"] == "feedback_response" for row in notifications.json())
    assert (
        client.post("/notifications/read-all", headers=owner["headers"]).status_code
        == 200
    )
    unread = client.get("/notifications/unread-count", headers=owner["headers"])
    assert unread.json() == {"count": 0}

    revoked = client.delete(f"/wardrobe-shares/{share_id}", headers=owner["headers"])
    assert revoked.status_code == 200
    assert client.get(item["image_url"], headers=friend["headers"]).status_code == 403


@pytest.mark.whitebox
@pytest.mark.asyncio
async def test_ai_falls_back_and_rejects_invented_ids(mocker):
    invalid = schemas.AIRecommendation(
        title="Invented",
        items=[schemas.AIRecommendationItem(clothing_item_id=999, reason="Nope")],
        explanation=["Invalid"],
    )
    valid = schemas.AIRecommendation(
        title="Fallback",
        items=[schemas.AIRecommendationItem(clothing_item_id=1, reason="Valid")],
        explanation=["Uses a real item"],
    )
    mocker.patch("ai_service._gemini_generate", new=AsyncMock(return_value=invalid))
    ollama = mocker.patch(
        "ai_service._ollama_generate", new=AsyncMock(return_value=valid)
    )

    result = await get_outfit_recommendation(
        [{"id": 1, "name": "shirt"}], "casual", "mild"
    )
    assert result["provider"] == "ollama"
    ollama.assert_awaited_once()
