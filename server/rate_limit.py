import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request

# ponytail: in-process limits are enough for the single-worker deployment; use a
# shared Redis limiter if the service is scaled across multiple workers/instances.
_hits = defaultdict(deque)


def limit(requests: int, seconds: int):
    async def dependency(request: Request):
        now = time.monotonic()
        client = request.client.host if request.client else "unknown"
        key = (client, request.url.path)
        history = _hits[key]
        while history and history[0] <= now - seconds:
            history.popleft()
        if len(history) >= requests:
            raise HTTPException(
                status_code=429, detail="Too many requests. Try again later."
            )
        history.append(now)

    return dependency
