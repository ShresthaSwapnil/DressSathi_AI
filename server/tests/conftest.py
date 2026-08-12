import os
from io import BytesIO

import pytest
from fastapi.testclient import TestClient
from PIL import Image
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

os.environ["DATABASE_URL"] = "sqlite://"
os.environ["JWT_SECRET_KEY"] = "test-secret"
os.environ["ENVIRONMENT"] = "test"

from database import Base, get_db  # noqa: E402
from main import app  # noqa: E402
from rate_limit import _hits  # noqa: E402
from routers import items  # noqa: E402

engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def override_db():
    db = TestingSession()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_db


@pytest.fixture(autouse=True)
def clean_state(tmp_path, monkeypatch):
    _hits.clear()
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    upload_root = tmp_path / "uploads"
    upload_root.mkdir()
    monkeypatch.setattr(items, "_UPLOAD_ROOT", upload_root)
    yield
    app.dependency_overrides[get_db] = override_db


@pytest.fixture
def client():
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def png_bytes():
    buffer = BytesIO()
    Image.new("RGB", (4, 4), "navy").save(buffer, format="PNG")
    return buffer.getvalue()


@pytest.fixture
def account(client):
    def create(email="owner@example.com", password="correct-horse"):
        registered = client.post(
            "/auth/register", json={"email": email, "password": password}
        )
        assert registered.status_code == 200, registered.text
        logged_in = client.post(
            "/auth/login", data={"username": email, "password": password}
        )
        assert logged_in.status_code == 200, logged_in.text
        return {
            "id": registered.json()["id"],
            "email": email,
            "headers": {"Authorization": f"Bearer {logged_in.json()['access_token']}"},
        }

    return create


@pytest.fixture
def wardrobe_item(client, png_bytes, mocker):
    def create(account, name="Navy shirt"):
        mocker.patch(
            "routers.items.process_upload_with_bg_removal",
            side_effect=lambda path: path,
        )
        uploaded = client.post(
            "/items/upload",
            headers=account["headers"],
            files={"file": ("shirt.png", png_bytes, "image/png")},
        )
        assert uploaded.status_code == 200, uploaded.text
        created = client.post(
            "/items/",
            headers=account["headers"],
            json={
                "image_url": uploaded.json()["url"],
                "name": name,
                "category": "Tops",
                "color": "Navy",
                "style": "Casual",
                "season": "All-season",
            },
        )
        assert created.status_code == 200, created.text
        return created.json()

    return create
