from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class ClothingItemBase(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    color: Optional[str] = None

class ClothingItemCreate(ClothingItemBase):
    image_url: str

class ClothingItemResponse(ClothingItemBase):
    id: int
    user_id: int
    image_url: str

    model_config = ConfigDict(from_attributes=True)
