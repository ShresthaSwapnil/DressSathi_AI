"""
AI Service — Ollama (gemma3:4b) primary, Gemini 2.5 Pro fallback.
Handles both text-based outfit recommendations and image analysis for tagging.
"""

import os
import json
import base64
import httpx
import google.generativeai as genai
from dotenv import load_dotenv
from typing import Optional, List, Dict

load_dotenv()

# ── Configuration ──
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "gemma3:4b")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL_NAME", "gemini-2.5-pro")

# Initialize Gemini as fallback
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    gemini_model = genai.GenerativeModel(GEMINI_MODEL)
else:
    gemini_model = None


async def _ollama_generate(prompt: str, images: Optional[List[str]] = None) -> Optional[str]:
    """Call Ollama API. Returns response text or None on failure."""
    try:
        payload = {
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": False,
        }
        if images:
            payload["images"] = images  # base64-encoded images

        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(f"{OLLAMA_BASE_URL}/api/generate", json=payload)
            if resp.status_code == 200:
                return resp.json().get("response", "")
            return None
    except Exception:
        return None


def _gemini_generate(prompt: str, image_bytes: Optional[bytes] = None, mime_type: Optional[str] = None) -> Optional[str]:
    """Call Gemini API as fallback. Returns response text or None on failure."""
    if not gemini_model:
        return None
    try:
        if image_bytes and mime_type:
            import PIL.Image
            import io
            image = PIL.Image.open(io.BytesIO(image_bytes))
            response = gemini_model.generate_content([prompt, image])
        else:
            response = gemini_model.generate_content(prompt)
        return response.text.strip()
    except Exception:
        return None


async def get_outfit_recommendation(wardrobe_text: str, occasion: str, weather: str) -> Dict[str, str]:
    """Get AI outfit recommendation. Tries Ollama first, falls back to Gemini."""
    prompt = f"""You are a professional fashion stylist. I want an outfit recommendation from my wardrobe for a {occasion} occasion.
The current weather is {weather}.

My Wardrobe:
{wardrobe_text}

Please suggest a complete outfit using ONLY items from my wardrobe.
Give me a clear recommendation and a short explanation of why it works well together.
Limit your response to 3-4 sentences."""

    # Try Ollama first
    result = await _ollama_generate(prompt)
    if result:
        return {"text": result, "model_used": "ollama/%s" % OLLAMA_MODEL}

    # Fallback to Gemini
    result = _gemini_generate(prompt)
    if result:
        return {"text": result, "model_used": "gemini/%s" % GEMINI_MODEL}

    return {"text": "Sorry, AI services are currently unavailable. Please try again later.", "model_used": "none"}


async def analyze_clothing_image(image_path: str) -> Dict[str, Optional[str]]:
    """Analyze a clothing image and return predicted tags. Tries Ollama first, falls back to Gemini."""
    prompt = """Analyze this clothing image and return ONLY a valid JSON object with these fields:
{
  "category": "one of: Tops, Bottoms, Dresses, Outerwear, Shoes, Accessories",
  "color": "the dominant color of the clothing",
  "style": "one of: casual, formal, sporty, streetwear, bohemian, classic",
  "season": "one of: summer, winter, spring, fall, all-season"
}
Return ONLY the JSON, no other text."""

    # Read image
    with open(image_path, "rb") as f:
        image_bytes = f.read()

    image_b64 = base64.b64encode(image_bytes).decode("utf-8")

    # Determine mime type
    ext = image_path.rsplit(".", 1)[-1].lower()
    mime_map = {"jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png", "webp": "image/webp"}
    mime_type = mime_map.get(ext, "image/jpeg")

    # Try Ollama first (with image)
    result = await _ollama_generate(prompt, images=[image_b64])
    model_used = "ollama/%s" % OLLAMA_MODEL

    if not result:
        # Fallback to Gemini
        result = _gemini_generate(prompt, image_bytes=image_bytes, mime_type=mime_type)
        model_used = "gemini/%s" % GEMINI_MODEL

    if not result:
        return {"category": None, "color": None, "style": None, "season": None, "model_used": "none"}

    # Parse JSON from response
    try:
        # Try to extract JSON from the response (handle markdown code blocks)
        clean = result.strip()
        if clean.startswith("```"):
            clean = clean.split("\n", 1)[1] if "\n" in clean else clean
            clean = clean.rsplit("```", 1)[0]
        tags = json.loads(clean.strip())
        tags["model_used"] = model_used
        return tags
    except (json.JSONDecodeError, ValueError):
        return {"category": None, "color": None, "style": None, "season": None, "model_used": model_used, "raw": result}
