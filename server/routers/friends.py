from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

import models
import schemas
from database import get_db
from routers.auth import get_current_user
from routers.notifications import create_notification

router = APIRouter(prefix="/friends", tags=["friends"])


def pair_key(first_id: int, second_id: int) -> str:
    return ":".join(map(str, sorted((first_id, second_id))))


def are_friends(db: Session, first_id: int, second_id: int) -> bool:
    return (
        db.query(models.Friendship)
        .filter(
            or_(
                models.Friendship.pair_key == pair_key(first_id, second_id),
                (
                    (models.Friendship.requester_id == first_id)
                    & (models.Friendship.addressee_id == second_id)
                ),
                (
                    (models.Friendship.requester_id == second_id)
                    & (models.Friendship.addressee_id == first_id)
                ),
            ),
            models.Friendship.status == models.FriendshipStatus.accepted,
        )
        .first()
        is not None
    )


def _response(friendship, current_user_id: int):
    friend = (
        friendship.addressee
        if friendship.requester_id == current_user_id
        else friendship.requester
    )
    return schemas.FriendshipResponse(
        id=friendship.id,
        requester_id=friendship.requester_id,
        addressee_id=friendship.addressee_id,
        friend_user_id=friend.id,
        status=friendship.status,
        friend_email=friend.email,
        created_at=friendship.created_at,
    )


@router.get("/search", response_model=list[schemas.UserResponse])
def search_users(
    q: str = Query(..., min_length=2, max_length=100),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(models.User)
        .filter(
            models.User.id != current_user.id,
            models.User.email.ilike(f"%{q.strip()}%"),
        )
        .order_by(models.User.email)
        .limit(20)
        .all()
    )


@router.post("/request", response_model=schemas.FriendshipResponse)
def send_friend_request(
    request: schemas.FriendRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    addressee = (
        db.query(models.User)
        .filter(models.User.email == request.addressee_email.lower())
        .first()
    )
    if not addressee:
        raise HTTPException(status_code=404, detail="User not found.")
    if addressee.id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot add yourself.")
    key = pair_key(current_user.id, addressee.id)
    existing = (
        db.query(models.Friendship)
        .filter(
            or_(
                models.Friendship.pair_key == key,
                (
                    (models.Friendship.requester_id == current_user.id)
                    & (models.Friendship.addressee_id == addressee.id)
                ),
                (
                    (models.Friendship.requester_id == addressee.id)
                    & (models.Friendship.addressee_id == current_user.id)
                ),
            )
        )
        .first()
    )
    if existing and existing.status != models.FriendshipStatus.rejected:
        raise HTTPException(
            status_code=409,
            detail=f"Friendship already exists ({existing.status}).",
        )
    if existing:
        existing.requester_id = current_user.id
        existing.addressee_id = addressee.id
        existing.pair_key = key
        existing.status = models.FriendshipStatus.pending
        existing.updated_at = datetime.now(timezone.utc)
        friendship = existing
    else:
        friendship = models.Friendship(
            requester_id=current_user.id,
            addressee_id=addressee.id,
            pair_key=key,
            status=models.FriendshipStatus.pending,
        )
        db.add(friendship)
    try:
        db.flush()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409, detail="Friend request already exists."
        ) from exc
    create_notification(
        db,
        addressee.id,
        "friend_request",
        "New friend request",
        f"{current_user.email} sent you a friend request.",
        "friendship",
        friendship.id,
    )
    db.commit()
    db.refresh(friendship)
    return _response(friendship, current_user.id)


@router.get("/requests", response_model=list[schemas.FriendshipResponse])
def get_friend_requests(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(models.Friendship)
        .filter(
            models.Friendship.addressee_id == current_user.id,
            models.Friendship.status == models.FriendshipStatus.pending,
        )
        .order_by(models.Friendship.created_at.desc())
        .all()
    )
    return [_response(row, current_user.id) for row in rows]


@router.get("/requests/sent", response_model=list[schemas.FriendshipResponse])
def get_sent_requests(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(models.Friendship)
        .filter(
            models.Friendship.requester_id == current_user.id,
            models.Friendship.status == models.FriendshipStatus.pending,
        )
        .order_by(models.Friendship.created_at.desc())
        .all()
    )
    return [_response(row, current_user.id) for row in rows]


@router.post("/accept/{friendship_id}", response_model=schemas.FriendshipResponse)
def accept_friend_request(
    friendship_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    friendship = (
        db.query(models.Friendship)
        .filter(
            models.Friendship.id == friendship_id,
            models.Friendship.addressee_id == current_user.id,
            models.Friendship.status == models.FriendshipStatus.pending,
        )
        .first()
    )
    if not friendship:
        raise HTTPException(status_code=404, detail="Pending request not found.")
    friendship.status = models.FriendshipStatus.accepted
    friendship.pair_key = pair_key(friendship.requester_id, friendship.addressee_id)
    create_notification(
        db,
        friendship.requester_id,
        "friend_accepted",
        "Friend request accepted",
        f"{current_user.email} accepted your friend request.",
        "friendship",
        friendship.id,
    )
    db.commit()
    db.refresh(friendship)
    return _response(friendship, current_user.id)


@router.post("/reject/{friendship_id}", response_model=schemas.FriendshipResponse)
def reject_friend_request(
    friendship_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    friendship = (
        db.query(models.Friendship)
        .filter(
            models.Friendship.id == friendship_id,
            models.Friendship.addressee_id == current_user.id,
            models.Friendship.status == models.FriendshipStatus.pending,
        )
        .first()
    )
    if not friendship:
        raise HTTPException(status_code=404, detail="Pending request not found.")
    friendship.status = models.FriendshipStatus.rejected
    db.commit()
    db.refresh(friendship)
    return _response(friendship, current_user.id)


@router.delete("/request/{friendship_id}")
def cancel_friend_request(
    friendship_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    friendship = (
        db.query(models.Friendship)
        .filter(
            models.Friendship.id == friendship_id,
            models.Friendship.requester_id == current_user.id,
            models.Friendship.status == models.FriendshipStatus.pending,
        )
        .first()
    )
    if not friendship:
        raise HTTPException(status_code=404, detail="Pending request not found.")
    db.delete(friendship)
    db.commit()
    return {"message": "Friend request cancelled."}


@router.get("/", response_model=list[schemas.FriendshipResponse])
def list_friends(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(models.Friendship)
        .filter(
            or_(
                models.Friendship.requester_id == current_user.id,
                models.Friendship.addressee_id == current_user.id,
            ),
            models.Friendship.status == models.FriendshipStatus.accepted,
        )
        .all()
    )
    return [_response(row, current_user.id) for row in rows]


@router.delete("/{friendship_id}")
def remove_friend(
    friendship_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    friendship = (
        db.query(models.Friendship)
        .filter(
            models.Friendship.id == friendship_id,
            or_(
                models.Friendship.requester_id == current_user.id,
                models.Friendship.addressee_id == current_user.id,
            ),
            models.Friendship.status == models.FriendshipStatus.accepted,
        )
        .first()
    )
    if not friendship:
        raise HTTPException(status_code=404, detail="Friendship not found.")
    other_id = (
        friendship.addressee_id
        if friendship.requester_id == current_user.id
        else friendship.requester_id
    )
    db.query(models.WardrobeShare).filter(
        or_(
            (models.WardrobeShare.owner_id == current_user.id)
            & (models.WardrobeShare.friend_id == other_id),
            (models.WardrobeShare.owner_id == other_id)
            & (models.WardrobeShare.friend_id == current_user.id),
        ),
        models.WardrobeShare.revoked_at.is_(None),
    ).update({models.WardrobeShare.revoked_at: datetime.now(timezone.utc)})
    db.delete(friendship)
    db.commit()
    return {"message": "Friend removed."}
