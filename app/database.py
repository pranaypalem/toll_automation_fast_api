import os
import sqlite3
from datetime import datetime, timedelta
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from passlib.context import CryptContext

# Database setup
DATABASE_URL = "sqlite:///./toll_automation.db"
if os.environ.get("AWS_LAMBDA_FUNCTION_NAME"):
    # In Lambda, use /tmp directory
    DATABASE_URL = "sqlite:///tmp/toll_automation.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, default=datetime.utcnow)


class UploadHistory(Base):
    __tablename__ = "upload_history"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    original_filename = Column(String, nullable=False)
    processed_filename = Column(String, nullable=False)
    file_size = Column(Integer, nullable=False)
    upload_date = Column(DateTime, default=datetime.utcnow)
    s3_key = Column(String)  # S3 path for processed file
    

def create_tables():
    """Create database tables"""
    Base.metadata.create_all(bind=engine)


def get_db():
    """Database dependency for FastAPI"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Hash password"""
    return pwd_context.hash(password)


def get_user_by_email(db, email: str):
    """Get user by email"""
    return db.query(User).filter(User.email == email).first()


def create_user(db, email: str, password: str):
    """Create new user"""
    hashed_password = get_password_hash(password)
    db_user = User(email=email, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def get_user_uploads(db, user_id: int, days: int = 30, limit: int = 10):
    """Get user's upload history from past N days, limited to max items"""
    cutoff_date = datetime.utcnow() - timedelta(days=days)
    return db.query(UploadHistory).filter(
        UploadHistory.user_id == user_id,
        UploadHistory.upload_date >= cutoff_date
    ).order_by(UploadHistory.upload_date.desc()).limit(limit).all()


def add_upload_record(db, user_id: int, original_filename: str, 
                     processed_filename: str, file_size: int, s3_key: str = None):
    """Add upload record to history"""
    record = UploadHistory(
        user_id=user_id,
        original_filename=original_filename,
        processed_filename=processed_filename,
        file_size=file_size,
        s3_key=s3_key
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record