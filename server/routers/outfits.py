from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
import models
import schemas
from routers.auth import get_current_user

router = APIRouter(prefix="/outfits", tags=["outfits"])

@router.post("/save", response_model=schemas.OutfitResponse)
def save_outfit(
    outfit: schemas.OutfitSave,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db_outfit = models.SavedOutfit(
        user_id=current_user.id,
        occasion=outfit.occasion,
        weather=outfit.weather,
        recommendation_text=outfit.recommendation_text,
        item_ids=outfit.item_ids,
    )
    db.add(db_outfit)
    db.commit()
    db.refresh(db_outfit)
    return db_outfit

@router.get("/", response_model=List[schemas.OutfitResponse])
def list_outfits(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(models.SavedOutfit).filter(
        models.SavedOutfit.user_id == current_user.id
    ).order_by(models.SavedOutfit.created_at.desc()).all()

@router.delete("/{outfit_id}")
def delete_outfit(
    outfit_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    outfit = db.query(models.SavedOutfit).filter(
        models.SavedOutfit.id == outfit_id,
        models.SavedOutfit.user_id == current_user.id
    ).first()
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
    db: Session = Depends(get_db)
):
    # Verify outfit ownership
    outfit = db.query(models.SavedOutfit).filter(
        models.SavedOutfit.id == outfit_id,
        models.SavedOutfit.user_id == current_user.id
    ).first()
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found.")

    # Verify friendship
    friendship = db.query(models.Friendship).filter(
        ((models.Friendship.requester_id == current_user.id) & (models.Friendship.addressee_id == share.friend_user_id)) |
        ((models.Friendship.requester_id == share.friend_user_id) & (models.Friendship.addressee_id == current_user.id)),
        models.Friendship.status == models.FriendshipStatus.accepted
    ).first()
    if not friendship:
        raise HTTPException(status_code=400, detail="You can only share outfits with friends.")

    shared = models.SharedOutfit(
        outfit_id=outfit_id,
        shared_by=current_user.id,
        shared_with=share.friend_user_id,
    )
    db.add(shared)
    db.commit()
    db.refresh(shared)
    return {"message": "Outfit shared successfully.", "shared_id": shared.id}

@router.get("/shared", response_model=List[schemas.SharedOutfitResponse])
def get_shared_outfits(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    shared = db.query(models.SharedOutfit).filter(
        models.SharedOutfit.shared_with == current_user.id
    ).all()

    result = []
    for s in shared:
        result.append(schemas.SharedOutfitResponse(
            id=s.id,
            outfit_id=s.outfit_id,
            shared_by=s.shared_by,
            shared_with=s.shared_with,
            shared_by_email=s.sender.email,
            recommendation_text=s.outfit.recommendation_text if s.outfit else None,
            occasion=s.outfit.occasion if s.outfit else None,
            created_at=s.created_at,
        ))
    return result
