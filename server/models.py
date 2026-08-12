import enum
from datetime import datetime, timezone

from sqlalchemy import (
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from database import Base


def utcnow():
    return datetime.now(timezone.utc)


class FriendshipStatus(str, enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(320), unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    display_name = Column(String(100), nullable=True)
    style_preferences = Column(Text, nullable=True)
    location_name = Column(String(120), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    created_at = Column(DateTime, default=utcnow)

    items = relationship(
        "ClothingItem", back_populates="owner", cascade="all, delete-orphan"
    )
    saved_outfits = relationship(
        "SavedOutfit", back_populates="owner", cascade="all, delete-orphan"
    )


class ClothingItem(Base):
    __tablename__ = "clothing_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    image_url = Column(String, nullable=False)
    back_image_url = Column(String, nullable=True)
    name = Column(String(120), nullable=True)
    category = Column(String(40), nullable=True)
    color = Column(String(60), nullable=True)
    style = Column(String(40), nullable=True)
    season = Column(String(40), nullable=True)
    created_at = Column(DateTime, default=utcnow)

    owner = relationship("User", back_populates="items")


class SavedOutfit(Base):
    __tablename__ = "saved_outfits"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String(160), nullable=True)
    occasion = Column(String(60), nullable=True)
    weather = Column(String(160), nullable=True)
    recommendation_text = Column(Text, nullable=False)
    item_ids = Column(String, nullable=True)  # legacy; normalized rows live below
    provider = Column(String(30), nullable=True)
    model_used = Column(String(100), nullable=True)
    confidence_score = Column(Float, nullable=True)
    created_at = Column(DateTime, default=utcnow)

    owner = relationship("User", back_populates="saved_outfits")
    items = relationship(
        "OutfitItem",
        back_populates="outfit",
        cascade="all, delete-orphan",
        order_by="OutfitItem.position",
    )
    shares = relationship(
        "SharedOutfit", back_populates="outfit", cascade="all, delete-orphan"
    )


class OutfitItem(Base):
    __tablename__ = "outfit_items"
    __table_args__ = (
        UniqueConstraint("outfit_id", "clothing_item_id", name="uq_outfit_item"),
        UniqueConstraint("outfit_id", "position", name="uq_outfit_position"),
    )

    id = Column(Integer, primary_key=True)
    outfit_id = Column(
        Integer, ForeignKey("saved_outfits.id"), nullable=False, index=True
    )
    clothing_item_id = Column(
        Integer, ForeignKey("clothing_items.id"), nullable=False, index=True
    )
    position = Column(Integer, nullable=False)
    reason = Column(String(300), nullable=True)

    outfit = relationship("SavedOutfit", back_populates="items")
    clothing_item = relationship("ClothingItem")


class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(Integer, primary_key=True, index=True)
    requester_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    addressee_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    pair_key = Column(String(60), unique=True, nullable=True)
    status = Column(String(20), default=FriendshipStatus.pending, nullable=False)
    created_at = Column(DateTime, default=utcnow)
    updated_at = Column(DateTime, default=utcnow, onupdate=utcnow)

    requester = relationship("User", foreign_keys=[requester_id])
    addressee = relationship("User", foreign_keys=[addressee_id])


class SharedOutfit(Base):
    __tablename__ = "shared_outfits"
    __table_args__ = (
        UniqueConstraint("outfit_id", "shared_with", name="uq_outfit_recipient"),
    )

    id = Column(Integer, primary_key=True, index=True)
    outfit_id = Column(
        Integer, ForeignKey("saved_outfits.id"), nullable=False, index=True
    )
    shared_by = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    shared_with = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    created_at = Column(DateTime, default=utcnow)

    outfit = relationship("SavedOutfit", back_populates="shares")
    sender = relationship("User", foreign_keys=[shared_by])
    recipient = relationship("User", foreign_keys=[shared_with])
    comments = relationship(
        "FeedbackComment", back_populates="shared_outfit", cascade="all, delete-orphan"
    )


class FeedbackComment(Base):
    __tablename__ = "feedback_comments"

    id = Column(Integer, primary_key=True, index=True)
    shared_outfit_id = Column(
        Integer, ForeignKey("shared_outfits.id"), nullable=False, index=True
    )
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    comment = Column(Text, nullable=False)
    created_at = Column(DateTime, default=utcnow)

    shared_outfit = relationship("SharedOutfit", back_populates="comments")
    user = relationship("User")


class FeedbackRequest(Base):
    __tablename__ = "feedback_requests"

    id = Column(Integer, primary_key=True, index=True)
    requester_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    recipient_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    outfit_id = Column(Integer, ForeignKey("saved_outfits.id"), nullable=True)
    item_ids = Column(Text, nullable=True)
    message = Column(String(500), nullable=True)
    status = Column(String(20), default="pending", nullable=False, index=True)
    created_at = Column(DateTime, default=utcnow)
    responded_at = Column(DateTime, nullable=True)

    requester = relationship("User", foreign_keys=[requester_id])
    recipient = relationship("User", foreign_keys=[recipient_id])
    outfit = relationship("SavedOutfit")
    response = relationship(
        "FeedbackResponse",
        back_populates="request",
        cascade="all, delete-orphan",
        uselist=False,
    )


class FeedbackResponse(Base):
    __tablename__ = "feedback_responses"

    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(
        Integer,
        ForeignKey("feedback_requests.id"),
        nullable=False,
        unique=True,
        index=True,
    )
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    rating = Column(Integer, nullable=True)
    comment = Column(String(1000), nullable=True)
    created_at = Column(DateTime, default=utcnow)

    request = relationship("FeedbackRequest", back_populates="response")
    user = relationship("User")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    type = Column(String(40), nullable=False)
    title = Column(String(160), nullable=False)
    message = Column(String(500), nullable=False)
    related_type = Column(String(40), nullable=True)
    related_id = Column(Integer, nullable=True)
    read_at = Column(DateTime, nullable=True, index=True)
    created_at = Column(DateTime, default=utcnow)

    user = relationship("User")


class WardrobeShare(Base):
    __tablename__ = "wardrobe_shares"
    __table_args__ = (
        UniqueConstraint("owner_id", "friend_id", name="uq_wardrobe_share_pair"),
    )

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    friend_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    scope = Column(String(20), default="all", nullable=False)
    created_at = Column(DateTime, default=utcnow)
    revoked_at = Column(DateTime, nullable=True, index=True)
    expires_at = Column(DateTime, nullable=True)

    owner = relationship("User", foreign_keys=[owner_id])
    friend = relationship("User", foreign_keys=[friend_id])
    items = relationship(
        "WardrobeShareItem",
        back_populates="share",
        cascade="all, delete-orphan",
    )


class WardrobeShareItem(Base):
    __tablename__ = "wardrobe_share_items"
    __table_args__ = (
        UniqueConstraint("share_id", "clothing_item_id", name="uq_share_item"),
    )

    id = Column(Integer, primary_key=True)
    share_id = Column(
        Integer, ForeignKey("wardrobe_shares.id"), nullable=False, index=True
    )
    clothing_item_id = Column(
        Integer, ForeignKey("clothing_items.id"), nullable=False, index=True
    )

    share = relationship("WardrobeShare", back_populates="items")
    clothing_item = relationship("ClothingItem")
