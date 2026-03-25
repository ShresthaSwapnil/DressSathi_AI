import os
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
import google.generativeai as genai
from dotenv import load_dotenv

from database import get_db
import models
import schemas
from routers.auth import get_current_user

# Load environment variables
load_dotenv()

router = APIRouter(prefix="/recommendations", tags=["recommendations"])

# Initialize Gemini
api_key = os.getenv("GEMINI_API_KEY")
model_name = os.getenv("GEMINI_MODEL_NAME", "gemini-2.5-pro")

if api_key:
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(model_name)
else:
    model = None

@router.get("/outfit")
def recommend_outfit(
    occasion: Optional[str] = "casual",
    weather: Optional[str] = "clear",
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not model:
        raise HTTPException(
            status_code=500, 
            detail="Gemini API key not configured. Please add it to your .env file."
        )

    # 1. Fetch user items
    items = db.query(models.ClothingItem).filter(models.ClothingItem.user_id == current_user.id).all()
    
    if not items:
        return {"recommendation": "Your wardrobe is empty! Add some clothes so I can help you style them."}

    # 2. Format wardrobe for Gemini
    wardrobe_list = ""
    for idx, item in enumerate(items):
        wardrobe_list += f"- {item.name} ({item.category}, {item.color})\n"

    # 3. Construct the prompt
    prompt = f"""
    You are a professional fashion stylist. I want an outfit recommendation from my wardrobe for a {occasion} occasion. 
    The current weather is {weather}.
    
    My Wardrobe:
    {wardrobe_list}
    
    Please suggest a complete outfit using ONLY items from my wardrobe. 
    Give me a clear recommendation and a short explanation of why it works well together. 
    Limit your response to 3-4 sentences.
    """

    try:
        response = model.generate_content(prompt)
        return {
            "occasion": occasion,
            "weather": weather,
            "recommendation": response.text.strip(),
            "items_analyzed": len(items)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
