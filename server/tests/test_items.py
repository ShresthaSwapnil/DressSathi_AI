import pytest
from fastapi import HTTPException

from routers import items


@pytest.mark.blackbox
def test_upload_crud_search_and_media_authorization(client, account, wardrobe_item):
    owner = account()
    stranger = account("stranger@example.com")
    item = wardrobe_item(owner)

    listed = client.get("/items/", headers=owner["headers"])
    assert listed.status_code == 200
    assert [row["id"] for row in listed.json()] == [item["id"]]

    searched = client.get(
        "/items/search?search=navy&category=tops", headers=owner["headers"]
    )
    assert searched.status_code == 200
    assert searched.json()["total"] == 1

    media = client.get(item["image_url"], headers=owner["headers"])
    assert media.status_code == 200
    assert media.headers["content-type"] == "image/png"
    assert client.get(item["image_url"], headers=stranger["headers"]).status_code == 403

    updated = client.put(
        f"/items/{item['id']}",
        headers=owner["headers"],
        json={"name": "Updated shirt"},
    )
    assert updated.status_code == 200
    assert updated.json()["name"] == "Updated shirt"
    stolen = client.put(
        f"/items/{item['id']}",
        headers=stranger["headers"],
        json={"name": "Stolen"},
    )
    assert stolen.status_code == 404

    image_path = items._safe_resolve_upload_path(item["image_url"], must_exist=True)
    deleted = client.delete(f"/items/{item['id']}", headers=owner["headers"])
    assert deleted.status_code == 200
    assert not image_path.exists()


@pytest.mark.blackbox
def test_upload_rejects_non_image(client, account):
    response = client.post(
        "/items/upload",
        headers=account()["headers"],
        files={"file": ("payload.png", b"not an image", "image/png")},
    )
    assert response.status_code == 400
    assert "JPEG, PNG, and WebP" in response.json()["detail"]


@pytest.mark.whitebox
def test_upload_path_is_confined_to_upload_root(tmp_path, monkeypatch):
    root = tmp_path / "uploads"
    root.mkdir(exist_ok=True)
    monkeypatch.setattr(items, "_UPLOAD_ROOT", root)

    resolved = items._safe_resolve_upload_path("/media/../outside.png")
    assert resolved.parent == root.resolve()
    with pytest.raises(HTTPException):
        items._safe_resolve_upload_path("..")
