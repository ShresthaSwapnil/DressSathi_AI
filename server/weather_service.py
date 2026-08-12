import os

import httpx

import schemas

WEATHER_BASE_URL = os.getenv(
    "WEATHER_BASE_URL", "https://api.open-meteo.com/v1/forecast"
)
WEATHER_TIMEOUT_SECONDS = float(os.getenv("WEATHER_TIMEOUT_SECONDS", "8"))

_WEATHER_CODES = {
    0: "clear sky",
    1: "mainly clear",
    2: "partly cloudy",
    3: "overcast",
    45: "foggy",
    48: "foggy",
    51: "light drizzle",
    53: "drizzle",
    55: "heavy drizzle",
    61: "light rain",
    63: "rain",
    65: "heavy rain",
    71: "light snow",
    73: "snow",
    75: "heavy snow",
    80: "rain showers",
    81: "rain showers",
    82: "heavy rain showers",
    95: "thunderstorm",
}


async def get_current_weather(latitude: float, longitude: float):
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "current": "temperature_2m,apparent_temperature,precipitation,weather_code",
        "timezone": "auto",
    }
    async with httpx.AsyncClient(timeout=WEATHER_TIMEOUT_SECONDS) as client:
        response = await client.get(WEATHER_BASE_URL, params=params)
        response.raise_for_status()
    current = response.json()["current"]
    code = int(current["weather_code"])
    condition = _WEATHER_CODES.get(code, "mixed conditions")
    temperature = float(current["temperature_2m"])
    apparent = float(current.get("apparent_temperature", temperature))
    precipitation = float(current.get("precipitation", 0))
    summary = f"{temperature:.0f}°C, {condition}; feels like {apparent:.0f}°C" + (
        f", precipitation {precipitation:g} mm" if precipitation else ""
    )
    return schemas.WeatherResponse(
        summary=summary,
        temperature_c=temperature,
        apparent_temperature_c=apparent,
        condition=condition,
        precipitation_mm=precipitation,
        weather_code=code,
        observed_at=str(current["time"]),
    )
