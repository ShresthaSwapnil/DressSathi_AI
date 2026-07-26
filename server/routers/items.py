import os
import shutil
from pathlib import Path
from uuid import uuid4
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from database import get_db
import models
import schemas
from routers.auth import get_current_user
from ai_service import analyze_clothing_image
from bg_removal_service import process_upload_with_bg_removal

router = APIRouter(prefix="/items", tags=["items"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Resolve once at module level so every comparison uses the same absolute root.
_UPLOAD_ROOT = Path(UPLOAD_DIR).resolve()


def _safe_resolve_upload_path(url_field: str) -> Optional[Path]:
    """Resolve an image URL to a filesystem path, rejecting anything outside UPLOAD_DIR.

    Returns the resolved Path if valid and existing, or None if the file does not exist.
    Raises HTTPException 400 if the path escapes the upload root.
    """
    # Strip the leading /uploads/ prefix to get the relative filename
    relative = url_field.lstrip("/")
    resolved = Path(relative).resolve()

    # Guard: the resolved path must be inside _UPLOAD_ROOT
    if not str(resolved).startswith(str(_UPLOAD_ROOT)):
        raise HTTPException(
            status_code=400,
            detail="Invalid file path: references a location outside the upload directory.",
        )

    if resolved.exists():
        return resolved
    return None


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
    """List all wardrobe items for the current user (plain list, backward-compatible)."""
    items = db.query(models.ClothingItem).filter(
        models.ClothingItem.user_id == current_user.id
    ).order_by(models.ClothingItem.created_at.desc()).offset(skip).limit(limit).all()
    return items

@router.get("/search", response_model=schemas.PaginatedItemsResponse)
def search_items(
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page (max 100)"),
    search: Optional[str] = Query(None, description="Search by item name"),
    category: Optional[str] = Query(None, description="Filter by category"),
    color: Optional[str] = Query(None, description="Filter by color"),
    style: Optional[str] = Query(None, description="Filter by style"),
    season: Optional[str] = Query(None, description="Filter by season"),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Search and filter wardrobe items with pagination metadata."""
    query = db.query(models.ClothingItem).filter(
        models.ClothingItem.user_id == current_user.id
    )

    # Apply filters
    if search:
        query = query.filter(models.ClothingItem.name.ilike(f"%{search}%"))
    if category:
        query = query.filter(models.ClothingItem.category.ilike(category))
    if color:
        query = query.filter(models.ClothingItem.color.ilike(color))
    if style:
        query = query.filter(models.ClothingItem.style.ilike(style))
    if season:
        query = query.filter(models.ClothingItem.season.ilike(season))

    # Total count before pagination
    total = query.count()

    # Order by newest first, then paginate
    items = (
        query.order_by(models.ClothingItem.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )

    return schemas.PaginatedItemsResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=items,
    )

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

    # Clean up image files from disk — using safe resolver
    for url_field in [item.image_url, item.back_image_url]:
        if url_field:
            resolved = _safe_resolve_upload_path(url_field)
            if resolved is not None:
                resolved.unlink()

    db.delete(item)
    db.commit()
    return {"message": "Item deleted successfully."}
