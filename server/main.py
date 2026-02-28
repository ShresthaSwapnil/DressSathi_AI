from fastapi import FastAPI

app = FastAPI(title="DressSathi API", description="Backend API for the DressSathi application")

@app.get("/")
def read_root():
    return {"message": "Welcome to the DressSathi API"}

@app.get("/health")
def health_check():
    return {"status": "ok"}
