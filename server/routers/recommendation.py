import os

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

import models
import schemas
from ai_service import AIServiceUnavailable, get_outfit_recommendation
from database import get_db
from rate_limit import limit
from routers.auth import get_current_user
from weather_service import get_current_weather

router = APIRouter(prefix="/recommendations", tags=["recommendations"])


async def _recommend(
    request: schemas.RecommendationRequest,
    current_user: models.User,
    db: Session,
):
    query = db.query(models.ClothingItem).filter(
        models.ClothingItem.user_id == current_user.id
    )
    if request.selected_item_ids:
        query = query.filter(models.ClothingItem.id.in_(request.selected_item_ids))
    items = query.all()
    if not items:
        raise HTTPException(
            status_code=400, detail="Add wardrobe items before requesting an outfit."
        )
    if request.selected_item_ids and len(items) != len(set(request.selected_item_ids)):
        raise HTTPException(
            status_code=400, detail="One or more selected items are invalid."
        )

    weather_summary = request.manual_weather or "weather unavailable"
    if request.use_live_weather:
        latitude = (
            request.latitude if request.latitude is not None else current_user.latitude
        )
        longitude = (
            request.longitude
            if request.longitude is not None
            else current_user.longitude
        )
        latitude = (
            latitude
            if latitude is not None
            else float(os.getenv("DEFAULT_LATITUDE", "27.7172"))
        )
        longitude = (
            longitude
            if longitude is not None
            else float(os.getenv("DEFAULT_LONGITUDE", "85.3240"))
        )
        try:
            weather_summary = (await get_current_weather(latitude, longitude)).summary
        except Exception:
            if not request.manual_weather:
                weather_summary = "current weather unavailable; use all-season layers"

    wardrobe = [
        {
            "id": item.id,
            "name": item.name,
            "category": item.category,
            "color": item.color,
            "style": item.style,
            "season": item.season,
        }
        for item in items
    ]
    try:
        generated = await get_outfit_recommendation(
            wardrobe,
            request.occasion,
            weather_summary,
            current_user.style_preferences,
            request.additional_context,
        )
    except AIServiceUnavailable as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    result = generated["recommendation"]
    by_id = {item.id: item for item in items}
    recommended = [
        schemas.RecommendedItemResponse(
            clothing_item_id=row.clothing_item_id,
            name=by_id[row.clothing_item_id].name,
            category=by_id[row.clothing_item_id].category,
            color=by_id[row.clothing_item_id].color,
            image_url=by_id[row.clothing_item_id].image_url,
            reason=row.reason,
        )
        for row in result.items
    ]
    return schemas.RecommendationResponse(
        title=result.title,
        occasion=request.occasion,
        weather_summary=weather_summary,
        items=recommended,
        explanation=result.explanation,
        confidence_score=result.confidence_score,
        provider=generated["provider"],
        model_used=generated["model"],
        items_analyzed=len(items),
    )


@router.post(
    "",
    response_model=schemas.RecommendationResponse,
    dependencies=[Depends(limit(10, 60))],
)
async def recommend_outfit(
    request: schemas.RecommendationRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return await _recommend(request, current_user, db)


@router.get("/outfit", response_model=schemas.RecommendationResponse)
async def recommend_outfit_compat(
    occasion: str = "casual",
    weather: str = "clear",
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    request = schemas.RecommendationRequest(
        occasion=occasion, manual_weather=weather, use_live_weather=False
    )
    return await _recommend(request, current_user, db)
