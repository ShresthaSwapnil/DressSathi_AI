import io
import os
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import List, Optional
from uuid import uuid4

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from fastapi.responses import FileResponse
from PIL import Image, UnidentifiedImageError
from sqlalchemy import or_
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool

import models
import schemas
from ai_service import analyze_clothing_image
from bg_removal_service import process_upload_with_bg_removal
from database import get_db
from rate_limit import limit
from routers.auth import get_current_user

router = APIRouter(prefix="/items", tags=["items"])
media_router = APIRouter(tags=["media"])

UPLOAD_DIR = os.getenv("UPLOAD_DIR", "uploads")
MAX_UPLOAD_BYTES = int(os.getenv("MAX_UPLOAD_BYTES", str(10 * 1024 * 1024)))
_UPLOAD_ROOT = Path(UPLOAD_DIR).resolve()
_UPLOAD_ROOT.mkdir(parents=True, exist_ok=True)
_FORMATS = {"JPEG": "jpg", "PNG": "png", "WEBP": "webp"}


def _safe_resolve_upload_path(value: str, must_exist: bool = False) -> Path:
    name = PurePosixPath(value).name
    if not name or name in {".", ".."}:
        raise HTTPException(status_code=400, detail="Invalid media path.")
    resolved = (_UPLOAD_ROOT / name).resolve()
    try:
        resolved.relative_to(_UPLOAD_ROOT)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid media path.") from exc
    if must_exist and not resolved.is_file():
        raise HTTPException(status_code=400, detail="Uploaded image does not exist.")
    return resolved


async def _save_valid_image(file: UploadFile, user_id: int, prefix: str = "") -> Path:
    data = await file.read(MAX_UPLOAD_BYTES + 1)
    if not data or len(data) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Image must be 10 MB or smaller.")
    try:
        with Image.open(io.BytesIO(data)) as image:
            image.verify()
            extension = _FORMATS.get(image.format or "")
    except (UnidentifiedImageError, OSError):
        extension = None
    if not extension:
        raise HTTPException(
            status_code=400, detail="Only JPEG, PNG, and WebP images are supported."
        )
    path = _UPLOAD_ROOT / f"{user_id}_{prefix}{uuid4().hex}.{extension}"
    path.write_bytes(data)
    return path


def _owned_upload(value: str, user_id: int) -> Path:
    path = _safe_resolve_upload_path(value, must_exist=True)
    if not path.name.startswith(f"{user_id}_"):
        raise HTTPException(
            status_code=403, detail="Image does not belong to this user."
        )
    return path


@router.post("/upload", dependencies=[Depends(limit(30, 60))])
async def upload_image(
    file: UploadFile = File(...), current_user: models.User = Depends(get_current_user)
):
    temp_path = await _save_valid_image(file, current_user.id)
    try:
        final_path = Path(
            await run_in_threadpool(process_upload_with_bg_removal, str(temp_path))
        )
    except RuntimeError as exc:
        temp_path.unlink(missing_ok=True)
        raise HTTPException(status_code=500, detail="Image processing failed.") from exc
    return {"url": f"/media/{final_path.name}"}


@router.post(
    "/analyze",
    response_model=schemas.AITagResponse,
    dependencies=[Depends(limit(30, 60))],
)
async def analyze_image(
    file: UploadFile = File(...), current_user: models.User = Depends(get_current_user)
):
    temp_path = await _save_valid_image(file, current_user.id, "analysis_")
    try:
        tags = await analyze_clothing_image(str(temp_path))
        return schemas.AITagResponse(**tags)
    finally:
        temp_path.unlink(missing_ok=True)


@router.post("/", response_model=schemas.ClothingItemResponse)
def create_item(
    item: schemas.ClothingItemCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _owned_upload(item.image_url, current_user.id)
    if item.back_image_url:
        _owned_upload(item.back_image_url, current_user.id)
    db_item = models.ClothingItem(**item.model_dump(), user_id=current_user.id)
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


@router.get("/", response_model=List[schemas.ClothingItemResponse])
def read_items(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(models.ClothingItem)
        .filter(models.ClothingItem.user_id == current_user.id)
        .order_by(models.ClothingItem.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.get("/search", response_model=schemas.PaginatedItemsResponse)
def search_items(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None, max_length=120),
    category: Optional[str] = Query(None, max_length=40),
    color: Optional[str] = Query(None, max_length=60),
    style: Optional[str] = Query(None, max_length=40),
    season: Optional[str] = Query(None, max_length=40),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = db.query(models.ClothingItem).filter(
        models.ClothingItem.user_id == current_user.id
    )
    if search:
        query = query.filter(models.ClothingItem.name.ilike(f"%{search.strip()}%"))
    for column, value in (
        (models.ClothingItem.category, category),
        (models.ClothingItem.color, color),
        (models.ClothingItem.style, style),
        (models.ClothingItem.season, season),
    ):
        if value:
            query = query.filter(column.ilike(value.strip()))
    total = query.count()
    items = (
        query.order_by(models.ClothingItem.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )
    return schemas.PaginatedItemsResponse(
        total=total, page=page, page_size=page_size, items=items
    )


@router.get("/{item_id}", response_model=schemas.ClothingItemResponse)
def read_item(
    item_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    item = (
        db.query(models.ClothingItem)
        .filter(
            models.ClothingItem.id == item_id,
            models.ClothingItem.user_id == current_user.id,
        )
        .first()
    )
    if not item:
        raise HTTPException(status_code=404, detail="Item not found.")
    return item


@router.put("/{item_id}", response_model=schemas.ClothingItemResponse)
def update_item(
    item_id: int,
    update: schemas.ClothingItemUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    item = (
        db.query(models.ClothingItem)
        .filter(
            models.ClothingItem.id == item_id,
            models.ClothingItem.user_id == current_user.id,
        )
        .first()
    )
    if not item:
        raise HTTPException(status_code=404, detail="Item not found.")
    for key, value in update.model_dump(exclude_unset=True).items():
        setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return item


@router.delete("/{item_id}")
def delete_item(
    item_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    item = (
        db.query(models.ClothingItem)
        .filter(
            models.ClothingItem.id == item_id,
            models.ClothingItem.user_id == current_user.id,
        )
        .first()
    )
    if not item:
        raise HTTPException(status_code=404, detail="Item not found.")
    paths = [
        _safe_resolve_upload_path(value)
        for value in (item.image_url, item.back_image_url)
        if value
    ]
    db.delete(item)
    db.commit()
    for path in paths:
        path.unlink(missing_ok=True)
    return {"message": "Item deleted successfully."}


@media_router.get("/media/{filename}")
def read_media(
    filename: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    path = _safe_resolve_upload_path(filename, must_exist=True)
    if path.name.startswith(f"{current_user.id}_"):
        return FileResponse(path)

    urls = (f"/media/{path.name}", f"/uploads/{path.name}")
    item = (
        db.query(models.ClothingItem)
        .filter(
            or_(
                models.ClothingItem.image_url.in_(urls),
                models.ClothingItem.back_image_url.in_(urls),
            )
        )
        .first()
    )
    if not item:
        raise HTTPException(status_code=404, detail="Media not found.")
    if item.user_id == current_user.id:
        return FileResponse(path)

    shared_outfit = (
        db.query(models.SharedOutfit)
        .join(
            models.OutfitItem,
            models.OutfitItem.outfit_id == models.SharedOutfit.outfit_id,
        )
        .filter(
            models.SharedOutfit.shared_with == current_user.id,
            models.OutfitItem.clothing_item_id == item.id,
        )
        .first()
    )
    now = datetime.now(timezone.utc)
    wardrobe_share = (
        db.query(models.WardrobeShare)
        .filter(
            models.WardrobeShare.owner_id == item.user_id,
            models.WardrobeShare.friend_id == current_user.id,
            models.WardrobeShare.revoked_at.is_(None),
            or_(
                models.WardrobeShare.expires_at.is_(None),
                models.WardrobeShare.expires_at > now,
            ),
        )
        .first()
    )
    allowed_by_wardrobe = bool(
        wardrobe_share
        and (
            wardrobe_share.scope == "all"
            or any(row.clothing_item_id == item.id for row in wardrobe_share.items)
        )
    )
    if not shared_outfit and not allowed_by_wardrobe:
        raise HTTPException(status_code=403, detail="Media access denied.")
    return FileResponse(path)
