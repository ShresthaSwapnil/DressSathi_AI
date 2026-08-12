from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

import models
import schemas
from database import get_db
from routers.auth import get_current_user
from routers.friends import are_friends
from routers.notifications import create_notification

router = APIRouter(prefix="/wardrobe-shares", tags=["wardrobe sharing"])


def _active(row):
    if row.revoked_at is not None:
        return False
    if row.expires_at is None:
        return True
    expires = row.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    return expires > datetime.now(timezone.utc)


def _response(row):
    return schemas.WardrobeShareResponse(
        id=row.id,
        owner_id=row.owner_id,
        friend_id=row.friend_id,
        owner_email=row.owner.email,
        friend_email=row.friend.email,
        scope=row.scope,
        item_ids=[item.clothing_item_id for item in row.items],
        created_at=row.created_at,
        expires_at=row.expires_at,
        revoked_at=row.revoked_at,
    )


@router.post("", response_model=schemas.WardrobeShareResponse)
def create_share(
    data: schemas.WardrobeShareCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not are_friends(db, current_user.id, data.friend_user_id):
        raise HTTPException(
            status_code=400, detail="Wardrobes can only be shared with friends."
        )
    ids = list(dict.fromkeys(data.item_ids))
    if ids and db.query(models.ClothingItem).filter(
        models.ClothingItem.user_id == current_user.id,
        models.ClothingItem.id.in_(ids),
    ).count() != len(ids):
        raise HTTPException(status_code=400, detail="Invalid wardrobe item selection.")
    row = (
        db.query(models.WardrobeShare)
        .filter(
            models.WardrobeShare.owner_id == current_user.id,
            models.WardrobeShare.friend_id == data.friend_user_id,
        )
        .first()
    )
    if row:
        row.scope = "selected" if ids else "all"
        row.revoked_at = None
        row.expires_at = data.expires_at
        row.items.clear()
        db.flush()
    else:
        row = models.WardrobeShare(
            owner_id=current_user.id,
            friend_id=data.friend_user_id,
            scope="selected" if ids else "all",
            expires_at=data.expires_at,
        )
        db.add(row)
    for item_id in ids:
        row.items.append(models.WardrobeShareItem(clothing_item_id=item_id))
    db.flush()
    create_notification(
        db,
        data.friend_user_id,
        "wardrobe_shared",
        "Wardrobe shared",
        f"{current_user.email} shared wardrobe access with you.",
        "wardrobe_share",
        row.id,
    )
    db.commit()
    db.refresh(row)
    return _response(row)


@router.get("", response_model=list[schemas.WardrobeShareResponse])
def list_shares(
    box: str = Query("received", pattern="^(received|granted)$"),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    column = (
        models.WardrobeShare.friend_id
        if box == "received"
        else models.WardrobeShare.owner_id
    )
    rows = (
        db.query(models.WardrobeShare)
        .filter(column == current_user.id)
        .order_by(models.WardrobeShare.created_at.desc())
        .all()
    )
    return [_response(row) for row in rows if _active(row)]


@router.get("/{share_id}/items", response_model=list[schemas.ClothingItemResponse])
def get_shared_items(
    share_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    row = (
        db.query(models.WardrobeShare)
        .filter(models.WardrobeShare.id == share_id)
        .first()
    )
    if not row:
        raise HTTPException(status_code=404, detail="Wardrobe share not found.")
    if current_user.id not in (row.owner_id, row.friend_id):
        raise HTTPException(status_code=403, detail="Wardrobe access denied.")
    if current_user.id == row.friend_id and not _active(row):
        raise HTTPException(
            status_code=403, detail="Wardrobe access has expired or been revoked."
        )
    query = db.query(models.ClothingItem).filter(
        models.ClothingItem.user_id == row.owner_id
    )
    if row.scope == "selected":
        ids = [item.clothing_item_id for item in row.items]
        query = query.filter(models.ClothingItem.id.in_(ids))
    return query.order_by(models.ClothingItem.created_at.desc()).all()


@router.delete("/{share_id}")
def revoke_share(
    share_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    row = (
        db.query(models.WardrobeShare)
        .filter(
            models.WardrobeShare.id == share_id,
            models.WardrobeShare.owner_id == current_user.id,
        )
        .first()
    )
    if not row:
        raise HTTPException(status_code=404, detail="Wardrobe share not found.")
    row.revoked_at = datetime.now(timezone.utc)
    create_notification(
        db,
        row.friend_id,
        "wardrobe_revoked",
        "Wardrobe access revoked",
        f"{current_user.email} revoked wardrobe access.",
        "wardrobe_share",
        row.id,
    )
    db.commit()
    return {"message": "Wardrobe access revoked."}
