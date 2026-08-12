from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

import models
import schemas
from database import get_db
from routers.auth import get_current_user
from routers.friends import are_friends
from routers.notifications import create_notification

router = APIRouter(prefix="/feedback", tags=["feedback"])


def _request_response(row):
    item_ids = (
        [int(value) for value in row.item_ids.split(",") if value]
        if row.item_ids
        else []
    )
    return schemas.FeedbackRequestResponse(
        id=row.id,
        requester_id=row.requester_id,
        recipient_id=row.recipient_id,
        requester_email=row.requester.email,
        recipient_email=row.recipient.email,
        outfit_id=row.outfit_id,
        item_ids=item_ids,
        message=row.message,
        status=row.status,
        rating=row.response.rating if row.response else None,
        response_comment=row.response.comment if row.response else None,
        created_at=row.created_at,
        responded_at=row.responded_at,
    )


@router.post("/requests", response_model=schemas.FeedbackRequestResponse)
def create_feedback_request(
    data: schemas.FeedbackRequestCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not data.outfit_id and not data.item_ids:
        raise HTTPException(
            status_code=400, detail="Select an outfit or wardrobe items."
        )
    if not are_friends(db, current_user.id, data.recipient_id):
        raise HTTPException(
            status_code=400, detail="Feedback can only be requested from friends."
        )
    if (
        data.outfit_id
        and not db.query(models.SavedOutfit)
        .filter(
            models.SavedOutfit.id == data.outfit_id,
            models.SavedOutfit.user_id == current_user.id,
        )
        .first()
    ):
        raise HTTPException(status_code=400, detail="Invalid outfit.")
    ids = list(dict.fromkeys(data.item_ids))
    if ids and db.query(models.ClothingItem).filter(
        models.ClothingItem.user_id == current_user.id,
        models.ClothingItem.id.in_(ids),
    ).count() != len(ids):
        raise HTTPException(status_code=400, detail="Invalid wardrobe item selection.")
    row = models.FeedbackRequest(
        requester_id=current_user.id,
        recipient_id=data.recipient_id,
        outfit_id=data.outfit_id,
        item_ids=",".join(map(str, ids)) or None,
        message=data.message,
    )
    db.add(row)
    db.flush()
    create_notification(
        db,
        data.recipient_id,
        "feedback_request",
        "Outfit feedback requested",
        f"{current_user.email} asked for your outfit feedback.",
        "feedback_request",
        row.id,
    )
    db.commit()
    db.refresh(row)
    return _request_response(row)


@router.get("/requests", response_model=list[schemas.FeedbackRequestResponse])
def list_feedback_requests(
    box: str = Query("inbox", pattern="^(inbox|sent)$"),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    column = (
        models.FeedbackRequest.recipient_id
        if box == "inbox"
        else models.FeedbackRequest.requester_id
    )
    rows = (
        db.query(models.FeedbackRequest)
        .filter(column == current_user.id)
        .order_by(models.FeedbackRequest.created_at.desc())
        .all()
    )
    return [_request_response(row) for row in rows]


@router.post(
    "/requests/{request_id}/respond", response_model=schemas.FeedbackRequestResponse
)
def respond_to_feedback(
    request_id: int,
    data: schemas.FeedbackRequestRespond,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if data.rating is None and data.comment is None:
        raise HTTPException(status_code=400, detail="Provide a rating or comment.")
    row = (
        db.query(models.FeedbackRequest)
        .filter(
            models.FeedbackRequest.id == request_id,
            models.FeedbackRequest.recipient_id == current_user.id,
            models.FeedbackRequest.status == "pending",
        )
        .first()
    )
    if not row:
        raise HTTPException(
            status_code=404, detail="Pending feedback request not found."
        )
    row.response = models.FeedbackResponse(
        user_id=current_user.id,
        rating=data.rating,
        comment=data.comment,
    )
    row.status = "responded"
    row.responded_at = datetime.now(timezone.utc)
    create_notification(
        db,
        row.requester_id,
        "feedback_response",
        "New outfit feedback",
        f"{current_user.email} responded to your feedback request.",
        "feedback_request",
        row.id,
    )
    db.commit()
    db.refresh(row)
    return _request_response(row)


@router.delete("/requests/{request_id}")
def cancel_feedback_request(
    request_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    row = (
        db.query(models.FeedbackRequest)
        .filter(
            models.FeedbackRequest.id == request_id,
            models.FeedbackRequest.requester_id == current_user.id,
            models.FeedbackRequest.status == "pending",
        )
        .first()
    )
    if not row:
        raise HTTPException(
            status_code=404, detail="Pending feedback request not found."
        )
    row.status = "cancelled"
    db.commit()
    return {"message": "Feedback request cancelled."}


@router.post("/{shared_outfit_id}", response_model=schemas.FeedbackResponse)
def post_comment(
    shared_outfit_id: int,
    feedback: schemas.FeedbackCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    shared = (
        db.query(models.SharedOutfit)
        .filter(models.SharedOutfit.id == shared_outfit_id)
        .first()
    )
    if not shared:
        raise HTTPException(status_code=404, detail="Shared outfit not found.")
    if current_user.id not in (shared.shared_by, shared.shared_with):
        raise HTTPException(status_code=403, detail="Not authorized for this outfit.")
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


@router.get("/{shared_outfit_id}", response_model=list[schemas.FeedbackResponse])
def get_comments(
    shared_outfit_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    shared = (
        db.query(models.SharedOutfit)
        .filter(models.SharedOutfit.id == shared_outfit_id)
        .first()
    )
    if not shared:
        raise HTTPException(status_code=404, detail="Shared outfit not found.")
    if current_user.id not in (shared.shared_by, shared.shared_with):
        raise HTTPException(status_code=403, detail="Not authorized for this outfit.")
    rows = (
        db.query(models.FeedbackComment)
        .filter(models.FeedbackComment.shared_outfit_id == shared_outfit_id)
        .order_by(models.FeedbackComment.created_at)
        .all()
    )
    return [
        schemas.FeedbackResponse(
            id=row.id,
            shared_outfit_id=row.shared_outfit_id,
            user_id=row.user_id,
            user_email=row.user.email,
            comment=row.comment,
            created_at=row.created_at,
        )
        for row in rows
    ]
