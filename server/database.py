import os
import logging
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.exc import OperationalError

# Configure logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables (useful when running locally outside Docker)
load_dotenv()

# Default to SQLite for fast local iteration without docker requirement initially, 
# although Docker-compose will set DATABASE_URL appropriately.
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./dresssathi.db")

# Fix postgres:// URL prefix for SQLAlchemy compatibility
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

def get_connected_engine(url):
    # check_same_thread is needed only for SQLite
    connect_args = {"check_same_thread": False} if url.startswith("sqlite") else {}
    test_engine = create_engine(url, connect_args=connect_args)
    try:
        # Attempt to connect to verify online status and accessibility
        with test_engine.connect() as conn:
            pass
        return test_engine
    except OperationalError as e:
        if url.startswith("sqlite"):
            raise e
        # Redact credentials from logs
        safe_url = url.split('@')[-1] if '@' in url else url
        logger.warning(f"Could not connect to database at {safe_url}. Error: {e}")
        logger.warning("Falling back to local SQLite database.")
        return None

engine = None
if DATABASE_URL and not DATABASE_URL.startswith("sqlite"):
    engine = get_connected_engine(DATABASE_URL)

if engine is None:
    # Fallback to local SQLite database
    SQLITE_URL = "sqlite:///./dresssathi.db"
    engine = create_engine(SQLITE_URL, connect_args={"check_same_thread": False})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
