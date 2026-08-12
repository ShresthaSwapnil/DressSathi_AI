import asyncio
import base64
import json
import logging
import os
from pathlib import Path
from typing import Optional, Type

import httpx
from google import genai
from google.genai import types
from pydantic import BaseModel, ValidationError

import schemas

logger = logging.getLogger(__name__)

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "gemma3:4b")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL_NAME", "gemini-2.5-flash")
AI_TIMEOUT_SECONDS = float(os.getenv("AI_TIMEOUT_SECONDS", "30"))


class AIServiceUnavailable(RuntimeError):
    pass


def _parse_model(schema: Type[BaseModel], value) -> Optional[BaseModel]:
    try:
        if isinstance(value, schema):
            return value
        if isinstance(value, dict):
            return schema.model_validate(value)
        return schema.model_validate_json(value)
    except (ValidationError, ValueError, TypeError):
        return None


async def _gemini_generate(
    prompt: str,
    schema: Type[BaseModel],
    image_bytes: Optional[bytes] = None,
    mime_type: Optional[str] = None,
):
    if not GEMINI_API_KEY:
        return None
    client = genai.Client(api_key=GEMINI_API_KEY)
    async_client = client.aio
    contents = [prompt]
    if image_bytes and mime_type:
        contents.append(types.Part.from_bytes(data=image_bytes, mime_type=mime_type))
    try:
        response = await asyncio.wait_for(
            async_client.models.generate_content(
                model=GEMINI_MODEL,
                contents=contents,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=schema,
                    temperature=0.3,
                ),
            ),
            timeout=AI_TIMEOUT_SECONDS,
        )
        return _parse_model(schema, response.parsed or response.text)
    except Exception as exc:
        logger.warning("Gemini generation failed: %s", type(exc).__name__)
        return None
    finally:
        await async_client.aclose()
        client.close()


async def _ollama_generate(
    prompt: str,
    schema: Type[BaseModel],
    image_bytes: Optional[bytes] = None,
):
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "format": schema.model_json_schema(),
        "stream": False,
        "options": {"temperature": 0.3},
    }
    if image_bytes:
        payload["images"] = [base64.b64encode(image_bytes).decode()]
    try:
        async with httpx.AsyncClient(timeout=AI_TIMEOUT_SECONDS) as client:
            response = await client.post(
                f"{OLLAMA_BASE_URL}/api/generate", json=payload
            )
            response.raise_for_status()
        return _parse_model(schema, response.json().get("response", ""))
    except Exception as exc:
        logger.warning("Ollama generation failed: %s", type(exc).__name__)
        return None


def _valid_recommendation(result, allowed_ids):
    if not result:
        return None
    ids = [item.clothing_item_id for item in result.items]
    if len(ids) != len(set(ids)) or not set(ids).issubset(allowed_ids):
        return None
    return result


async def get_outfit_recommendation(
    wardrobe: list,
    occasion: str,
    weather: str,
    preferences: Optional[str] = None,
    additional_context: Optional[str] = None,
):
    allowed_ids = {item["id"] for item in wardrobe}
    prompt = (
        "You are a practical fashion stylist. Select a complete outfit using ONLY "
        "the supplied wardrobe item IDs. Never invent an item. If the wardrobe is "
        "limited, choose the best safe subset and explain the limitation.\n"
        f"Occasion: {occasion}\nWeather: {weather}\n"
        f"Style preferences: {preferences or 'none supplied'}\n"
        f"Additional context: {additional_context or 'none supplied'}\n"
        f"Wardrobe JSON: {json.dumps(wardrobe, ensure_ascii=True)}"
    )

    result = _valid_recommendation(
        await _gemini_generate(prompt, schemas.AIRecommendation), allowed_ids
    )
    if result:
        return {"recommendation": result, "provider": "gemini", "model": GEMINI_MODEL}

    result = _valid_recommendation(
        await _ollama_generate(prompt, schemas.AIRecommendation), allowed_ids
    )
    if result:
        return {"recommendation": result, "provider": "ollama", "model": OLLAMA_MODEL}
    raise AIServiceUnavailable(
        "Both AI providers are unavailable or returned invalid data."
    )


async def analyze_clothing_image(image_path: str):
    path = Path(image_path)
    image_bytes = path.read_bytes()
    mime_type = {".png": "image/png", ".webp": "image/webp"}.get(
        path.suffix.lower(), "image/jpeg"
    )
    prompt = (
        "Classify the single clothing item. Category must be Tops, Bottoms, Dresses, "
        "Outerwear, Shoes, or Accessories. Style should be casual, formal, sporty, "
        "streetwear, bohemian, or classic. Season should be summer, winter, spring, "
        "fall, or all-season. Return only the requested structured fields."
    )
    valid_categories = {
        "tops",
        "bottoms",
        "dresses",
        "outerwear",
        "shoes",
        "accessories",
    }

    for provider, model, call in (
        (
            "gemini",
            GEMINI_MODEL,
            _gemini_generate(prompt, schemas.ClothingTags, image_bytes, mime_type),
        ),
        (
            "ollama",
            OLLAMA_MODEL,
            _ollama_generate(prompt, schemas.ClothingTags, image_bytes),
        ),
    ):
        result = await call
        if result and result.category and result.category.lower() in valid_categories:
            return {**result.model_dump(), "model_used": f"{provider}/{model}"}
    raise AIServiceUnavailable("Clothing analysis providers are unavailable.")
