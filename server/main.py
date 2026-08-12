import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from database import engine
from routers import (
    auth,
    feedback,
    friends,
    items,
    notifications,
    outfits,
    recommendation,
    shares,
    weather,
)

app = FastAPI(
    title="DressMate API",
    description="Backend API for the DressMate fashion assistant",
    version="1.0.0",
)

origins = [
    origin.strip()
    for origin in os.getenv(
        "CORS_ORIGINS", "http://localhost:3000,http://localhost:8080"
    ).split(",")
    if origin.strip()
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(auth.router)
app.include_router(items.media_router)
app.include_router(items.router)
app.include_router(recommendation.router)
app.include_router(weather.router)
app.include_router(friends.router)
app.include_router(outfits.router)
app.include_router(feedback.router)
app.include_router(notifications.router)
app.include_router(shares.router)


@app.get("/")
def read_root():
    return {"message": "Welcome to the DressMate API"}


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.get("/ready")
def readiness_check():
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))
    return {"status": "ready"}
