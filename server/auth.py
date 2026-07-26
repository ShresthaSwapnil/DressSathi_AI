import os
import logging
from datetime import datetime, timedelta, timezone
from passlib.context import CryptContext
from jose import JWTError, jwt
from typing import Optional

logger = logging.getLogger(__name__)

# Use environment variables in production
_DEFAULT_SECRET = "your-super-secret-key-for-development-only"
SECRET_KEY = os.environ.get("JWT_SECRET_KEY", _DEFAULT_SECRET)
ENVIRONMENT = os.environ.get("ENVIRONMENT", "development").lower()

# Block production startup with the default dev secret
if ENVIRONMENT == "production" and SECRET_KEY == _DEFAULT_SECRET:
    raise RuntimeError(
        "FATAL: Cannot start in production with the default JWT secret. "
        "Set a strong, unique JWT_SECRET_KEY environment variable."
    )

if SECRET_KEY == _DEFAULT_SECRET:
    logger.warning(
        "Using default development JWT secret. "
        "Set JWT_SECRET_KEY for any non-local environment."
    )

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days for MVP convenience

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

import hashlib

def verify_password(plain_password, hashed_password):
    sha256_hash = hashlib.sha256(plain_password.encode()).hexdigest()
    return pwd_context.verify(sha256_hash, hashed_password)

def get_password_hash(password):
    sha256_hash = hashlib.sha256(password.encode()).hexdigest()
    return pwd_context.hash(sha256_hash)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
