from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text, Enum as SQLEnum
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime, timezone
import enum

class FriendshipStatus(str, enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    items = relationship("ClothingItem", back_populates="owner", cascade="all, delete-orphan")
    saved_outfits = relationship("SavedOutfit", back_populates="owner", cascade="all, delete-orphan")

class ClothingItem(Base):
    __tablename__ = "clothing_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    image_url = Column(String, nullable=False)
    back_image_url = Column(String, nullable=True)   # back view of the item
    name = Column(String, nullable=True)
    category = Column(String, nullable=True)
    color = Column(String, nullable=True)
    style = Column(String, nullable=True)       # casual, formal, sporty, etc.
    season = Column(String, nullable=True)       # summer, winter, all-season, etc.
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    owner = relationship("User", back_populates="items")

class SavedOutfit(Base):
    __tablename__ = "saved_outfits"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    occasion = Column(String, nullable=True)
    weather = Column(String, nullable=True)
    recommendation_text = Column(Text, nullable=False)
    item_ids = Column(String, nullable=True)  # comma-separated item IDs
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    owner = relationship("User", back_populates="saved_outfits")
    shares = relationship("SharedOutfit", back_populates="outfit", cascade="all, delete-orphan")

class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(Integer, primary_key=True, index=True)
    requester_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    addressee_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String, default=FriendshipStatus.pending)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    requester = relationship("User", foreign_keys=[requester_id])
    addressee = relationship("User", foreign_keys=[addressee_id])

class SharedOutfit(Base):
    __tablename__ = "shared_outfits"

    id = Column(Integer, primary_key=True, index=True)
    outfit_id = Column(Integer, ForeignKey("saved_outfits.id"), nullable=False)
    shared_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    shared_with = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    outfit = relationship("SavedOutfit", back_populates="shares")
    sender = relationship("User", foreign_keys=[shared_by])
    recipient = relationship("User", foreign_keys=[shared_with])
    comments = relationship("FeedbackComment", back_populates="shared_outfit", cascade="all, delete-orphan")

class FeedbackComment(Base):
    __tablename__ = "feedback_comments"

    id = Column(Integer, primary_key=True, index=True)
    shared_outfit_id = Column(Integer, ForeignKey("shared_outfits.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    comment = Column(Text, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    shared_outfit = relationship("SharedOutfit", back_populates="comments")
    user = relationship("User")
