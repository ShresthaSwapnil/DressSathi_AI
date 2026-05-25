from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional

from database import get_db
import models
import schemas
from routers.auth import get_current_user
from ai_service import get_outfit_recommendation

router = APIRouter(prefix="/recommendations", tags=["recommendations"])

@router.get("/outfit")
async def recommend_outfit(
    occasion: Optional[str] = "casual",
    weather: Optional[str] = "clear",
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Fetch user items
    items = db.query(models.ClothingItem).filter(
        models.ClothingItem.user_id == current_user.id
    ).all()
    
    if not items:
        return {"recommendation": "Your wardrobe is empty! Add some clothes so I can help you style them."}

    # Format wardrobe for AI
    wardrobe_list = ""
    for item in items:
        parts = [item.name or "Unknown"]
        if item.category:
            parts.append(item.category)
        if item.color:
            parts.append(item.color)
        if item.style:
            parts.append(item.style)
        wardrobe_list += f"- {', '.join(parts)}\n"

    result = await get_outfit_recommendation(wardrobe_list, occasion, weather)

    return {
        "occasion": occasion,
        "weather": weather,
        "recommendation": result["text"],
        "model_used": result["model_used"],
        "items_analyzed": len(items)
    }
