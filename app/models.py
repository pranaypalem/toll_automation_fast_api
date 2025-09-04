from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    created_at: datetime
    last_login: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse


class UploadHistoryResponse(BaseModel):
    id: int
    original_filename: str
    processed_filename: str
    file_size: int
    upload_date: datetime

    class Config:
        from_attributes = True


class UserDashboard(BaseModel):
    user: UserResponse
    recent_uploads: list[UploadHistoryResponse]
    total_uploads: int