import os
from unittest.mock import patch
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
            try:
                os.remove(os.path.join("uploads", file))
            except OSError:
                pass

def get_auth_token():
    response = client.post(
        "/auth/login",
        data={"username": "test@user.com", "password": "pass123"}
    )
    return response.json()["access_token"]

def test_upload_image_success():
    token = get_auth_token()
    file_content = b"dummy image content"
    
    # Mock the background removal to avoid running the heavy ML model on dummy bytes
    with patch("routers.items.process_upload_with_bg_removal") as mock_bg_removal:
        mock_bg_removal.return_value = "uploads/dummy_file_nobg.png"
        
        response = client.post(
            "/items/upload",
            headers={"Authorization": f"Bearer {token}"},
            files={"file": ("test_image.jpg", file_content, "image/jpeg")}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "url" in data
        assert data["url"] == "/uploads/dummy_file_nobg.png"
        mock_bg_removal.assert_called_once()

def test_upload_image_invalid_type():
    token = get_auth_token()
    file_content = b"some text content"
    
    response = client.post(
        "/items/upload",
        headers={"Authorization": f"Bearer {token}"},
        files={"file": ("test.txt", file_content, "text/plain")}
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "File provided is not an image."

def test_create_and_read_item_front_and_back():
    token = get_auth_token()
    
    # 1. Create item with front and back images
    item_data = {
        "image_url": "/uploads/front_nobg.png",
        "back_image_url": "/uploads/back_nobg.png",
        "name": "Cozy Winter Jacket",
        "category": "Dresses",
        "color": "Red",
        "style": "Casual",
        "season": "Winter"
    }
    
    create_response = client.post(
        "/items/",
        headers={"Authorization": f"Bearer {token}"},
        json=item_data
    )
    assert create_response.status_code == 200, create_response.text
    created_item = create_response.json()
    assert created_item["name"] == "Cozy Winter Jacket"
    assert created_item["image_url"] == "/uploads/front_nobg.png"
    assert created_item["back_image_url"] == "/uploads/back_nobg.png"
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
    assert items_list[0]["back_image_url"] == "/uploads/back_nobg.png"

def test_create_item_front_only():
    token = get_auth_token()
    
    # Create item with only front image (back_image_url should be None/null)
    item_data = {
        "image_url": "/uploads/front_only_nobg.png",
        "name": "Summer Shorts",
        "category": "Bottoms",
        "color": "Green"
    }
    
    create_response = client.post(
        "/items/",
        headers={"Authorization": f"Bearer {token}"},
        json=item_data
    )
    assert create_response.status_code == 200, create_response.text
    created_item = create_response.json()
    assert created_item["name"] == "Summer Shorts"
    assert created_item["image_url"] == "/uploads/front_only_nobg.png"
    assert created_item["back_image_url"] is None

def test_delete_item_removes_both_files():
    token = get_auth_token()
    
    # Create dummy files on disk to test cleanup
    os.makedirs("uploads", exist_ok=True)
    front_file_path = "uploads/dummy_front_to_delete.png"
    back_file_path = "uploads/dummy_back_to_delete.png"
    
    with open(front_file_path, "w") as f:
        f.write("front")
    with open(back_file_path, "w") as f:
        f.write("back")
        
    assert os.path.exists(front_file_path)
    assert os.path.exists(back_file_path)
    
    # Create item in database
    item_data = {
        "image_url": f"/{front_file_path}",
        "back_image_url": f"/{back_file_path}",
        "name": "Temporary Shirt"
    }
    
    create_response = client.post(
        "/items/",
        headers={"Authorization": f"Bearer {token}"},
        json=item_data
    )
    item_id = create_response.json()["id"]
    
    # Delete the item
    delete_response = client.delete(
        f"/items/{item_id}",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert delete_response.status_code == 200
    
    # Verify files are deleted from the disk
    assert not os.path.exists(front_file_path)
    assert not os.path.exists(back_file_path)
