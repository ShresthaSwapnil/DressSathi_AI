from pydantic import BaseModel, EmailStr, ConfigDict, field_validator
from typing import Optional, List
from datetime import datetime

# ── Auth ──
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters long.")
        if len(v) > 128:
            raise ValueError("Password must be at most 128 characters long.")
        return v

class UserResponse(UserBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# ── Clothing Items ──
class ClothingItemBase(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    color: Optional[str] = None
    style: Optional[str] = None
    season: Optional[str] = None

class ClothingItemCreate(ClothingItemBase):
    image_url: str
    back_image_url: Optional[str] = None

    @field_validator("image_url")
    @classmethod
    def validate_image_url(cls, v: str) -> str:
        if not v.startswith("/uploads/"):
            raise ValueError("image_url must be a server-managed path starting with /uploads/.")
        if ".." in v:
            raise ValueError("image_url must not contain path traversal sequences.")
        return v

    @field_validator("back_image_url")
    @classmethod
    def validate_back_image_url(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            if not v.startswith("/uploads/"):
                raise ValueError("back_image_url must be a server-managed path starting with /uploads/.")
            if ".." in v:
                raise ValueError("back_image_url must not contain path traversal sequences.")
        return v

class ClothingItemUpdate(ClothingItemBase):
    """For partial updates — all fields optional."""
    pass

class ClothingItemResponse(ClothingItemBase):
    id: int
    user_id: int
    image_url: str
    back_image_url: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

# ── AI Tagging ──
class AITagResponse(BaseModel):
    category: Optional[str] = None
    color: Optional[str] = None
    style: Optional[str] = None
    season: Optional[str] = None
    confidence: Optional[str] = None
    model_used: Optional[str] = None

# ── Outfits ──
class OutfitSave(BaseModel):
    occasion: Optional[str] = None
    weather: Optional[str] = None
    recommendation_text: str
    item_ids: Optional[str] = None

class OutfitResponse(OutfitSave):
    id: int
    user_id: int
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

class OutfitShare(BaseModel):
    friend_user_id: int

class SharedOutfitResponse(BaseModel):
    id: int
    outfit_id: int
    shared_by: int
    shared_with: int
    shared_by_email: Optional[str] = None
    recommendation_text: Optional[str] = None
    occasion: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

# ── Friendships ──
class FriendRequest(BaseModel):
    addressee_email: str

class FriendshipResponse(BaseModel):
    id: int
    requester_id: int
    addressee_id: int
    status: str
    friend_email: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

# ── Feedback ──
class FeedbackCreate(BaseModel):
    comment: str

class FeedbackResponse(BaseModel):
    id: int
    shared_outfit_id: int
    user_id: int
    user_email: Optional[str] = None
    comment: str
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

# ── Paginated Responses ──
class PaginatedItemsResponse(BaseModel):
    total: int
    page: int
    page_size: int
    items: List[ClothingItemResponse]
