from fastapi import APIRouter, Depends, HTTPException, Query

import models
import schemas
from routers.auth import get_current_user
from weather_service import get_current_weather

router = APIRouter(prefix="/weather", tags=["weather"])


@router.get("/current", response_model=schemas.WeatherResponse)
async def current_weather(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    current_user: models.User = Depends(get_current_user),
):
    try:
        return await get_current_weather(latitude, longitude)
    except Exception as exc:
        raise HTTPException(
            status_code=503, detail="Weather service is unavailable."
        ) from exc
