from datetime import datetime
from pathlib import PurePosixPath
from typing import Dict, List, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class UserCreate(BaseModel):
    email: EmailStr
    password: str

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:
        if not 8 <= len(value) <= 128:
            raise ValueError("Password must be 8–128 characters long.")
        return value


class UserUpdate(BaseModel):
    display_name: Optional[str] = Field(None, max_length=100)
    style_preferences: Optional[str] = Field(None, max_length=500)
    location_name: Optional[str] = Field(None, max_length=120)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)


class UserResponse(UserUpdate):
    id: int
    email: EmailStr

    model_config = ConfigDict(from_attributes=True)


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None


class ClothingItemBase(BaseModel):
    name: Optional[str] = Field(None, max_length=120)
    category: Optional[str] = Field(None, max_length=40)
    color: Optional[str] = Field(None, max_length=60)
    style: Optional[str] = Field(None, max_length=40)
    season: Optional[str] = Field(None, max_length=40)


def _validate_media_url(value: Optional[str]) -> Optional[str]:
    if value is None:
        return value
    path = PurePosixPath(value)
    if path.parent not in (PurePosixPath("/media"), PurePosixPath("/uploads")):
        raise ValueError("Image must use a server-managed media path.")
    if path.name in ("", ".", ".."):
        raise ValueError("Invalid media filename.")
    return value


class ClothingItemCreate(ClothingItemBase):
    image_url: str
    back_image_url: Optional[str] = None

    @field_validator("image_url", "back_image_url")
    @classmethod
    def validate_media_url(cls, value):
        return _validate_media_url(value)


class ClothingItemUpdate(ClothingItemBase):
    pass


class ClothingItemResponse(ClothingItemBase):
    id: int
    user_id: int
    image_url: str
    back_image_url: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class PaginatedItemsResponse(BaseModel):
    total: int
    page: int
    page_size: int
    items: List[ClothingItemResponse]


class ClothingTags(BaseModel):
    category: Optional[str] = None
    color: Optional[str] = None
    style: Optional[str] = None
    season: Optional[str] = None


class AITagResponse(ClothingTags):
    confidence: Optional[float] = None
    model_used: Optional[str] = None


class AIRecommendationItem(BaseModel):
    clothing_item_id: int
    reason: str = Field(min_length=1, max_length=300)


class AIRecommendation(BaseModel):
    title: str = Field(min_length=1, max_length=160)
    items: List[AIRecommendationItem] = Field(min_length=1, max_length=8)
    explanation: List[str] = Field(min_length=1, max_length=6)
    confidence_score: Optional[float] = Field(None, ge=0, le=1)


class RecommendationRequest(BaseModel):
    occasion: str = Field("casual", min_length=1, max_length=60)
    manual_weather: Optional[str] = Field(None, max_length=160)
    use_live_weather: bool = True
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    selected_item_ids: List[int] = Field(default_factory=list, max_length=100)
    additional_context: Optional[str] = Field(None, max_length=300)


class RecommendedItemResponse(BaseModel):
    clothing_item_id: int
    name: Optional[str] = None
    category: Optional[str] = None
    color: Optional[str] = None
    image_url: str
    reason: str


class RecommendationResponse(BaseModel):
    title: str
    occasion: str
    weather_summary: str
    items: List[RecommendedItemResponse]
    explanation: List[str]
    confidence_score: Optional[float] = None
    provider: str
    model_used: str
    items_analyzed: int


class OutfitSave(BaseModel):
    title: Optional[str] = Field(None, max_length=160)
    occasion: Optional[str] = Field(None, max_length=60)
    weather: Optional[str] = Field(None, max_length=160)
    recommendation_text: str = Field(min_length=1, max_length=5000)
    item_ids: List[int] = Field(default_factory=list, max_length=8)
    reasons: Dict[int, str] = Field(default_factory=dict)
    provider: Optional[str] = Field(None, max_length=30)
    model_used: Optional[str] = Field(None, max_length=100)
    confidence_score: Optional[float] = Field(None, ge=0, le=1)


class OutfitItemResponse(BaseModel):
    clothing_item_id: int
    position: int
    reason: Optional[str] = None
    item: ClothingItemResponse


class OutfitResponse(BaseModel):
    id: int
    user_id: int
    title: Optional[str] = None
    occasion: Optional[str] = None
    weather: Optional[str] = None
    recommendation_text: str
    provider: Optional[str] = None
    model_used: Optional[str] = None
    confidence_score: Optional[float] = None
    items: List[OutfitItemResponse] = Field(default_factory=list)
    created_at: Optional[datetime] = None


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


class FriendRequest(BaseModel):
    addressee_email: EmailStr


class FriendshipResponse(BaseModel):
    id: int
    requester_id: int
    addressee_id: int
    friend_user_id: int
    status: str
    friend_email: Optional[str] = None
    created_at: Optional[datetime] = None


class FeedbackCreate(BaseModel):
    comment: str = Field(min_length=1, max_length=1000)


class FeedbackResponse(BaseModel):
    id: int
    shared_outfit_id: int
    user_id: int
    user_email: Optional[str] = None
    comment: str
    created_at: Optional[datetime] = None


class FeedbackRequestCreate(BaseModel):
    recipient_id: int
    outfit_id: Optional[int] = None
    item_ids: List[int] = Field(default_factory=list, max_length=12)
    message: Optional[str] = Field(None, max_length=500)


class FeedbackRequestRespond(BaseModel):
    rating: Optional[int] = Field(None, ge=1, le=5)
    comment: Optional[str] = Field(None, max_length=1000)

    @field_validator("comment")
    @classmethod
    def nonblank_comment(cls, value):
        if value is not None and not value.strip():
            raise ValueError("Comment cannot be blank.")
        return value


class FeedbackRequestResponse(BaseModel):
    id: int
    requester_id: int
    recipient_id: int
    requester_email: str
    recipient_email: str
    outfit_id: Optional[int] = None
    item_ids: List[int] = Field(default_factory=list)
    message: Optional[str] = None
    status: str
    rating: Optional[int] = None
    response_comment: Optional[str] = None
    created_at: datetime
    responded_at: Optional[datetime] = None


class NotificationResponse(BaseModel):
    id: int
    type: str
    title: str
    message: str
    related_type: Optional[str] = None
    related_id: Optional[int] = None
    read: bool
    created_at: datetime


class WardrobeShareCreate(BaseModel):
    friend_user_id: int
    item_ids: List[int] = Field(default_factory=list, max_length=100)
    expires_at: Optional[datetime] = None


class WardrobeShareResponse(BaseModel):
    id: int
    owner_id: int
    friend_id: int
    owner_email: str
    friend_email: str
    scope: str
    item_ids: List[int]
    created_at: datetime
    expires_at: Optional[datetime] = None
    revoked_at: Optional[datetime] = None


class WeatherResponse(BaseModel):
    summary: str
    temperature_c: float
    apparent_temperature_c: Optional[float] = None
    condition: str
    precipitation_mm: float = 0
    weather_code: int
    observed_at: str
    source: str = "Open-Meteo"
