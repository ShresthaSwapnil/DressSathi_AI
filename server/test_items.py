import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from main import app
from database import Base, get_db
from models import User
from auth import get_password_hash

SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

@pytest.fixture(autouse=True)
def run_around_tests():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    # Create a test user directly in DB
    user = User(email="test@user.com", hashed_password=get_password_hash("pass123"))
    db.add(user)
    db.commit()
    db.close()
    
    yield
    Base.metadata.drop_all(bind=engine)
    
    # Clean up uploads directory
    if os.path.exists("uploads"):
        for file in os.listdir("uploads"):
            os.remove(os.path.join("uploads", file))

def get_auth_token():
    response = client.post(
        "/auth/login",
        data={"username": "test@user.com", "password": "pass123"}
    )
    return response.json()["access_token"]

def test_upload_image():
    token = get_auth_token()
    
    # Create a dummy image file
    file_content = b"dummy image content"
    
    response = client.post(
        "/items/upload",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("test_image.jpg", file_content, "image/jpeg")}
    )
    assert response.status_code == 200
    data = response.json()
    assert "url" in data
    assert data["url"].startswith("/uploads/")
    assert data["url"].endswith(".jpg")

def test_create_and_read_item():
    token = get_auth_token()
    
    # 1. Create item
    item_data = {
        "image_url": "/uploads/test.jpg",
        "name": "My Favorite Shirt",
        "category": "Top",
        "color": "Blue"
    }
    
    create_response = client.post(
        "/items/",
        headers={"Authorization": f"Bearer {token}"},
        json=item_data
    )
    assert create_response.status_code == 200, create_response.text
    created_item = create_response.json()
    assert created_item["name"] == "My Favorite Shirt"
    assert "id" in created_item
    
    # 2. Read items
    read_response = client.get(
        "/items/",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert read_response.status_code == 200
    items_list = read_response.json()
    assert len(items_list) == 1
    assert items_list[0]["id"] == created_item["id"]
