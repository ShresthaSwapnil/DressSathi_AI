from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

import models
import schemas
from database import get_db
from routers.auth import get_current_user
from routers.friends import are_friends
from routers.notifications import create_notification

router = APIRouter(prefix="/outfits", tags=["outfits"])


def _response(outfit):
    return schemas.OutfitResponse(
        id=outfit.id,
        user_id=outfit.user_id,
        title=outfit.title,
        occasion=outfit.occasion,
        weather=outfit.weather,
        recommendation_text=outfit.recommendation_text,
        provider=outfit.provider,
        model_used=outfit.model_used,
        confidence_score=outfit.confidence_score,
        created_at=outfit.created_at,
        items=[
            schemas.OutfitItemResponse(
                clothing_item_id=row.clothing_item_id,
                position=row.position,
                reason=row.reason,
                item=row.clothing_item,
            )
            for row in outfit.items
        ],
    )


@router.post("/save", response_model=schemas.OutfitResponse)
def save_outfit(
    data: schemas.OutfitSave,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ids = list(dict.fromkeys(data.item_ids))
    items = (
        db.query(models.ClothingItem)
        .filter(
            models.ClothingItem.user_id == current_user.id,
            models.ClothingItem.id.in_(ids),
        )
        .all()
        if ids
        else []
    )
    if len(items) != len(ids):
        raise HTTPException(
            status_code=400, detail="One or more outfit items are invalid."
        )
    outfit = models.SavedOutfit(
        user_id=current_user.id,
        title=data.title,
        occasion=data.occasion,
        weather=data.weather,
        recommendation_text=data.recommendation_text,
        item_ids=",".join(map(str, ids)) or None,
        provider=data.provider,
        model_used=data.model_used,
        confidence_score=data.confidence_score,
    )
    db.add(outfit)
    db.flush()
    by_id = {item.id: item for item in items}
    for position, item_id in enumerate(ids):
        db.add(
            models.OutfitItem(
                outfit_id=outfit.id,
                clothing_item_id=item_id,
                position=position,
                reason=data.reasons.get(item_id),
            )
        )
    db.commit()
    db.refresh(outfit)
    for row in outfit.items:
        row.clothing_item = by_id[row.clothing_item_id]
    return _response(outfit)


@router.get("/", response_model=list[schemas.OutfitResponse])
def list_outfits(
    limit: int = Query(50, ge=1, le=100),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(models.SavedOutfit)
        .filter(models.SavedOutfit.user_id == current_user.id)
        .order_by(models.SavedOutfit.created_at.desc())
        .limit(limit)
        .all()
    )
    return [_response(row) for row in rows]


@router.get("/shared", response_model=list[schemas.SharedOutfitResponse])
def get_shared_outfits(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(models.SharedOutfit)
        .filter(models.SharedOutfit.shared_with == current_user.id)
        .order_by(models.SharedOutfit.created_at.desc())
        .all()
    )
    return [
        schemas.SharedOutfitResponse(
            id=row.id,
            outfit_id=row.outfit_id,
            shared_by=row.shared_by,
            shared_with=row.shared_with,
            shared_by_email=row.sender.email,
            recommendation_text=row.outfit.recommendation_text,
            occasion=row.outfit.occasion,
            created_at=row.created_at,
        )
        for row in rows
    ]


@router.get("/{outfit_id}", response_model=schemas.OutfitResponse)
def get_outfit(
    outfit_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    outfit = (
        db.query(models.SavedOutfit)
        .filter(
            models.SavedOutfit.id == outfit_id,
            models.SavedOutfit.user_id == current_user.id,
        )
        .first()
    )
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found.")
    return _response(outfit)


@router.delete("/{outfit_id}")
def delete_outfit(
    outfit_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    outfit = (
        db.query(models.SavedOutfit)
        .filter(
            models.SavedOutfit.id == outfit_id,
            models.SavedOutfit.user_id == current_user.id,
        )
        .first()
    )
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found.")
    db.delete(outfit)
    db.commit()
    return {"message": "Outfit deleted."}


@router.post("/{outfit_id}/share")
def share_outfit(
    outfit_id: int,
    share: schemas.OutfitShare,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    outfit = (
        db.query(models.SavedOutfit)
        .filter(
            models.SavedOutfit.id == outfit_id,
            models.SavedOutfit.user_id == current_user.id,
        )
        .first()
    )
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found.")
    if not are_friends(db, current_user.id, share.friend_user_id):
        raise HTTPException(status_code=400, detail="You can only share with friends.")
    row = models.SharedOutfit(
        outfit_id=outfit_id,
        shared_by=current_user.id,
        shared_with=share.friend_user_id,
    )
    db.add(row)
    try:
        db.flush()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409, detail="Outfit already shared with this friend."
        ) from exc
    create_notification(
        db,
        share.friend_user_id,
        "outfit_shared",
        "Outfit shared",
        f"{current_user.email} shared an outfit with you.",
        "shared_outfit",
        row.id,
    )
    db.commit()
    return {"message": "Outfit shared successfully.", "shared_id": row.id}
