import os
import shutil
from uuid import uuid4
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List

from database import get_db
import models
import schemas
from routers.auth import get_current_user
from ai_service import analyze_clothing_image
from bg_removal_service import process_upload_with_bg_removal

router = APIRouter(prefix="/items", tags=["items"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload", response_model=dict)
def upload_image(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user)
):
    """Upload an image, remove its background, and return the URL of the processed PNG."""
    # Basic validation
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File provided is not an image.")
        
    file_extension = file.filename.split(".")[-1]
    unique_filename = f"{uuid4()}.{file_extension}"
    temp_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    # Save the uploaded file temporarily
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Remove background synchronously — result is a .png with transparency
    try:
        final_path = process_upload_with_bg_removal(temp_path)
    except RuntimeError as e:
        # Clean up on failure
        if os.path.exists(temp_path):
            os.remove(temp_path)
        raise HTTPException(status_code=500, detail=str(e))
    
    # Return the URL relative to the static mount
    final_filename = os.path.basename(final_path)
    return {"url": f"/{UPLOAD_DIR}/{final_filename}"}

@router.post("/analyze", response_model=schemas.AITagResponse)
async def analyze_image(
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_user)
):
    """Upload an image and get AI-generated tags (category, color, style, season)."""
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File provided is not an image.")

    # Save temporarily
    file_extension = file.filename.split(".")[-1]
    temp_filename = f"temp_{uuid4()}.{file_extension}"
    temp_path = os.path.join(UPLOAD_DIR, temp_filename)

    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    try:
        tags = await analyze_clothing_image(temp_path)
        return schemas.AITagResponse(
            category=tags.get("category"),
            color=tags.get("color"),
            style=tags.get("style"),
            season=tags.get("season"),
            confidence=tags.get("confidence"),
            model_used=tags.get("model_used"),
        )
    finally:
        # Clean up temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)

@router.post("/", response_model=schemas.ClothingItemResponse)
def create_item(
    item: schemas.ClothingItemCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_item = models.ClothingItem(
        **item.model_dump(),
        user_id=current_user.id
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@router.get("/", response_model=List[schemas.ClothingItemResponse])
def read_items(
    skip: int = 0, 
    limit: int = 100,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    items = db.query(models.ClothingItem).filter(
        models.ClothingItem.user_id == current_user.id
    ).offset(skip).limit(limit).all()
    return items

@router.get("/{item_id}", response_model=schemas.ClothingItemResponse)
def read_item(
    item_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(models.ClothingItem).filter(
        models.ClothingItem.id == item_id,
        models.ClothingItem.user_id == current_user.id
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found.")
    return item

@router.put("/{item_id}", response_model=schemas.ClothingItemResponse)
def update_item(
    item_id: int,
    item_update: schemas.ClothingItemUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(models.ClothingItem).filter(
        models.ClothingItem.id == item_id,
        models.ClothingItem.user_id == current_user.id
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found.")

    update_data = item_update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if value is not None:
            setattr(item, key, value)

    db.commit()
    db.refresh(item)
    return item

@router.delete("/{item_id}")
def delete_item(
    item_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(models.ClothingItem).filter(
        models.ClothingItem.id == item_id,
        models.ClothingItem.user_id == current_user.id
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found.")

    # Clean up image files from disk
    for url_field in [item.image_url, item.back_image_url]:
        if url_field:
            file_path = url_field.lstrip("/")
            if os.path.exists(file_path):
                os.remove(file_path)

    db.delete(item)
    db.commit()
    return {"message": "Item deleted successfully."}
