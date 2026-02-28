from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from database import engine, Base
from routers import auth, items

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="DressSathi API", description="Backend API for the DressSathi application")

# Serve uploaded files statically
import os
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.include_router(auth.router)
app.include_router(items.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the DressSathi API"}

@app.get("/health")
def health_check():
    return {"status": "ok"}
