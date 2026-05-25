from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
import models
import schemas
from routers.auth import get_current_user

router = APIRouter(prefix="/feedback", tags=["feedback"])

@router.post("/{shared_outfit_id}", response_model=schemas.FeedbackResponse)
def post_comment(
    shared_outfit_id: int,
    feedback: schemas.FeedbackCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify the shared outfit exists and user is involved
    shared = db.query(models.SharedOutfit).filter(
        models.SharedOutfit.id == shared_outfit_id
    ).first()
    if not shared:
        raise HTTPException(status_code=404, detail="Shared outfit not found.")
    
    # Only the sender or recipient can comment
    if current_user.id not in [shared.shared_by, shared.shared_with]:
        raise HTTPException(status_code=403, detail="You are not authorized to comment on this outfit.")

    comment = models.FeedbackComment(
        shared_outfit_id=shared_outfit_id,
        user_id=current_user.id,
        comment=feedback.comment,
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)

    return schemas.FeedbackResponse(
        id=comment.id,
        shared_outfit_id=comment.shared_outfit_id,
        user_id=comment.user_id,
        user_email=current_user.email,
        comment=comment.comment,
        created_at=comment.created_at,
    )

@router.get("/{shared_outfit_id}", response_model=List[schemas.FeedbackResponse])
def get_comments(
    shared_outfit_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify the shared outfit exists and user is involved
    shared = db.query(models.SharedOutfit).filter(
        models.SharedOutfit.id == shared_outfit_id
    ).first()
    if not shared:
        raise HTTPException(status_code=404, detail="Shared outfit not found.")
    
    if current_user.id not in [shared.shared_by, shared.shared_with]:
        raise HTTPException(status_code=403, detail="You are not authorized to view these comments.")

    comments = db.query(models.FeedbackComment).filter(
        models.FeedbackComment.shared_outfit_id == shared_outfit_id
    ).order_by(models.FeedbackComment.created_at.asc()).all()

    return [
        schemas.FeedbackResponse(
            id=c.id,
            shared_outfit_id=c.shared_outfit_id,
            user_id=c.user_id,
            user_email=c.user.email,
            comment=c.comment,
            created_at=c.created_at,
        ) for c in comments
    ]
