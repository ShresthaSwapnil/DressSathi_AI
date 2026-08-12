# DressMate

DressMate is a Flutter and FastAPI wardrobe assistant completed through Sprint 8. It supports secure wardrobe media, Gemini-first AI recommendations with Ollama fallback, live weather, saved outfits, friends, feedback, notifications, and revocable wardrobe sharing.

## Sprint 1–8 scope

| Area | Included |
| --- | --- |
| Account | Registration, JWT login, secure local token storage, editable style/location profile |
| Wardrobe | Validated JPEG/PNG/WebP upload, background removal, front/back photos, CRUD, search/filter |
| Stylist | Structured recommendations from owned item IDs, Open-Meteo context, Gemini → Ollama fallback |
| Outfits | Normalized saved outfit history, item reasons, delete and friend sharing |
| Social | Friend request lifecycle, feedback requests/responses, notifications |
| Sharing | All/selected wardrobe access, authorization checks, expiry/revocation |
| Delivery | Alembic migrations, non-root Docker image, health checks, CI, black/white-box coverage |

## Run locally

Requirements: Python 3.11, Flutter stable, and optionally Docker/Ollama.

```bash
cp server/.env.example server/.env
cd server
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements-dev.txt
alembic upgrade head
uvicorn main:app --reload
```

The API docs are at `http://localhost:8000/docs`. In another terminal:

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Android emulators default to `http://10.0.2.2:8000`; iOS, desktop, and web default to loopback. Always pass `API_BASE_URL` for a deployed build.

Docker starts by applying migrations and then serving the API:

```bash
docker compose up --build
```

## Configuration

Copy [server/.env.example](server/.env.example). Production startup rejects SQLite and the default JWT secret. Required production values are:

```env
ENVIRONMENT=production
DATABASE_URL=postgresql://...
JWT_SECRET_KEY=<long-random-secret>
GEMINI_API_KEY=<key>
CORS_ORIGINS=https://your-app.example
UPLOAD_DIR=/persistent/uploads
```

Gemini is the primary provider. If it is unavailable or returns invented wardrobe IDs, the server validates and retries through Ollama. Open-Meteo does not require an API key.

## Tests

Backend tests use third-party `pytest`, `pytest-cov`, `pytest-mock`, and `pytest-asyncio`. Black-box tests call the public FastAPI API; white-box tests cover media confinement and AI-provider fallback.

```bash
cd server
pytest -m blackbox
pytest -m whitebox
pytest --cov=. --cov-report=term-missing --cov-fail-under=75
ruff format --check . && ruff check .
```

Frontend tests use `flutter_test`, Flutter `integration_test`, and `mocktail`:

```bash
cd app
flutter analyze
flutter test --coverage
flutter test integration_test/onboarding_flow_test.dart -d flutter-tester
```

CI runs both suites, checks a fresh migration, builds the release web app, and builds the API container.

## Release

```bash
cd app
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
flutter build ipa --release --dart-define=API_BASE_URL=https://api.example.com
```

Store signing credentials are intentionally not committed. Configure an Android upload key and Apple signing team/provisioning profile before store submission. Media storage must be persistent (or moved to object storage) before horizontal scaling; the current rate limiter is intentionally single-instance and should become Redis-backed when multiple API instances are deployed.
