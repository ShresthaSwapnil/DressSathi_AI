from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from database import engine, Base
from routers import auth, items, recommendation, friends, outfits, feedback

# Create database tables
Base.metadata.create_all(bind=engine)

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="DressSathi API", description="Backend API for the DressSathi application")

# Configure CORS for Flutter Web (and generic cross-origin API access)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for dev/testing
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve uploaded files statically
import os
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.include_router(auth.router)
app.include_router(items.router)
app.include_router(recommendation.router)
app.include_router(friends.router)
app.include_router(outfits.router)
app.include_router(feedback.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the DressSathi API"}

@app.get("/health")
def health_check():
    return {"status": "ok"}
