import pytest

from weather_service import get_current_weather


class FakeClient:
    def __init__(self, response):
        self.response = response

    async def __aenter__(self):
        return self

    async def __aexit__(self, *_):
        return None

    async def get(self, *_args, **_kwargs):
        return self.response


@pytest.mark.whitebox
@pytest.mark.asyncio
async def test_weather_response_is_normalized(mocker):
    response = mocker.Mock()
    response.raise_for_status = mocker.Mock()
    response.json.return_value = {
        "current": {
            "temperature_2m": 24.4,
            "apparent_temperature": 25.1,
            "precipitation": 0.5,
            "weather_code": 2,
            "time": "2026-08-12T12:00",
        }
    }
    mocker.patch(
        "weather_service.httpx.AsyncClient",
        return_value=FakeClient(response),
    )

    weather = await get_current_weather(27.7, 85.3)
    assert weather.condition == "partly cloudy"
    assert weather.temperature_c == 24.4
    assert "precipitation 0.5 mm" in weather.summary
