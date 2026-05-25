from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
import models
import schemas
from routers.auth import get_current_user

router = APIRouter(prefix="/friends", tags=["friends"])

@router.post("/request", response_model=schemas.FriendshipResponse)
def send_friend_request(
    req: schemas.FriendRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Find the addressee by email
    addressee = db.query(models.User).filter(models.User.email == req.addressee_email).first()
    if not addressee:
        raise HTTPException(status_code=404, detail="User not found.")
    if addressee.id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot send a friend request to yourself.")

    # Check if friendship already exists
    existing = db.query(models.Friendship).filter(
        ((models.Friendship.requester_id == current_user.id) & (models.Friendship.addressee_id == addressee.id)) |
        ((models.Friendship.requester_id == addressee.id) & (models.Friendship.addressee_id == current_user.id))
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail=f"Friendship already exists (status: {existing.status}).")

    friendship = models.Friendship(
        requester_id=current_user.id,
        addressee_id=addressee.id,
        status=models.FriendshipStatus.pending
    )
    db.add(friendship)
    db.commit()
    db.refresh(friendship)

    return schemas.FriendshipResponse(
        id=friendship.id,
        requester_id=friendship.requester_id,
        addressee_id=friendship.addressee_id,
        status=friendship.status,
        friend_email=addressee.email,
        created_at=friendship.created_at,
    )

@router.post("/accept/{friendship_id}", response_model=schemas.FriendshipResponse)
def accept_friend_request(
    friendship_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    friendship = db.query(models.Friendship).filter(
        models.Friendship.id == friendship_id,
        models.Friendship.addressee_id == current_user.id,
        models.Friendship.status == models.FriendshipStatus.pending
    ).first()
    if not friendship:
        raise HTTPException(status_code=404, detail="Pending friend request not found.")

    friendship.status = models.FriendshipStatus.accepted
    db.commit()
    db.refresh(friendship)

    return schemas.FriendshipResponse(
        id=friendship.id,
        requester_id=friendship.requester_id,
        addressee_id=friendship.addressee_id,
        status=friendship.status,
        friend_email=friendship.requester.email,
        created_at=friendship.created_at,
    )

@router.get("/requests", response_model=List[schemas.FriendshipResponse])
def get_friend_requests(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    requests = db.query(models.Friendship).filter(
        models.Friendship.addressee_id == current_user.id,
        models.Friendship.status == models.FriendshipStatus.pending
    ).all()

    return [
        schemas.FriendshipResponse(
            id=f.id,
            requester_id=f.requester_id,
            addressee_id=f.addressee_id,
            status=f.status,
            friend_email=f.requester.email,
            created_at=f.created_at,
        ) for f in requests
    ]

@router.get("/", response_model=List[schemas.FriendshipResponse])
def list_friends(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    friendships = db.query(models.Friendship).filter(
        ((models.Friendship.requester_id == current_user.id) | (models.Friendship.addressee_id == current_user.id)),
        models.Friendship.status == models.FriendshipStatus.accepted
    ).all()

    result = []
    for f in friendships:
        friend_email = f.addressee.email if f.requester_id == current_user.id else f.requester.email
        result.append(schemas.FriendshipResponse(
            id=f.id,
            requester_id=f.requester_id,
            addressee_id=f.addressee_id,
            status=f.status,
            friend_email=friend_email,
            created_at=f.created_at,
        ))
    return result
