import os
import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import FastAPI, File, HTTPException, UploadFile, Depends
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from .toll_processor import TollProcessor
from .database import get_db, create_tables, create_user, get_user_by_email, add_upload_record, get_user_uploads, User, UploadHistory
from .auth import authenticate_user, create_access_token, get_current_user, optional_get_current_user
from .models import UserCreate, UserLogin, Token, UserResponse, UserDashboard, UploadHistoryResponse

app = FastAPI(
    title="Toll Automation API",
    description="A FastAPI service for processing toll transaction data with user authentication",
    version="2.0.0",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database tables on startup
@app.on_event("startup")
def startup_event():
    create_tables()

# Use local directories for development, /tmp for Lambda
import os
if os.environ.get("AWS_LAMBDA_FUNCTION_NAME"):
    # Running in Lambda
    UPLOAD_DIR = "/tmp/uploads"
    OUTPUT_DIR = "/tmp/outputs"
else:
    # Running locally
    UPLOAD_DIR = "uploads"
    OUTPUT_DIR = "outputs"

# Ensure directories exist
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)


@app.get("/api")
async def root() -> dict[str, str]:
    return {"message": "Toll Automation API is running"}


# Authentication endpoints
@app.post("/auth/signup", response_model=Token)
async def signup(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    # Check if user already exists
    if get_user_by_email(db, user_data.email):
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    
    # Create new user
    user = create_user(db, user_data.email, user_data.password)
    
    # Create access token
    access_token = create_access_token(data={"sub": user.email})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }


@app.post("/auth/login", response_model=Token)
async def login(user_data: UserLogin, db: Session = Depends(get_db)):
    """Login user"""
    user = authenticate_user(db, user_data.email, user_data.password)
    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )
    
    # Update last login time
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Create access token
    access_token = create_access_token(data={"sub": user.email})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }


@app.get("/auth/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return current_user


@app.get("/dashboard", response_model=UserDashboard)
async def get_user_dashboard(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get user dashboard with upload history (last 30 days, max 10 items)"""
    recent_uploads = get_user_uploads(db, current_user.id, days=30, limit=10)
    
    return {
        "user": current_user,
        "recent_uploads": recent_uploads,
        "total_uploads": len(recent_uploads)
    }


@app.get("/health")
async def health_check() -> dict[str, str]:
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


@app.post("/process-toll-data")
async def process_toll_data(
    file: UploadFile = File(...), 
    current_user: Optional[User] = Depends(optional_get_current_user),
    db: Session = Depends(get_db)
) -> FileResponse:
    """
    Process toll transaction data from uploaded Excel file
    Returns processed data as CSV download
    """
    # File validation
    if not file.filename or not file.filename.endswith((".xlsx", ".xls", ".xlsm")):
        raise HTTPException(
            status_code=400, detail="File must be an Excel file (.xlsx, .xls, .xlsm)"
        )

    # Read file content and check size (5MB limit)
    content = await file.read()
    if len(content) > 5 * 1024 * 1024:  # 5MB limit
        raise HTTPException(status_code=413, detail="File size must be less than 5MB")

    try:
        # Generate unique filename for processing
        file_id = str(uuid.uuid4())
        temp_filename = f"{file_id}_{file.filename}"
        upload_path = os.path.join(UPLOAD_DIR, temp_filename)

        # Save uploaded file (content already read for size check)
        with open(upload_path, "wb") as f:
            f.write(content)
        
        # Verify file was written correctly
        if not os.path.exists(upload_path) or os.path.getsize(upload_path) != len(content):
            raise HTTPException(status_code=500, detail="File upload verification failed")
        
        # Additional file format validation
        if not file.filename.lower().endswith(('.xlsx', '.xls', '.xlsm')):
            raise HTTPException(status_code=400, detail="Invalid file format. Please upload .xlsx, .xls, or .xlsm files only")

        # Process the file
        processor = TollProcessor()
        processed_data = processor.process_excel_file(upload_path)

        # Save as CSV
        output_filename = f"processed_toll_data_{file_id}.csv"
        output_path = os.path.join(OUTPUT_DIR, output_filename)
        processed_data.to_csv(output_path, index=False)

        # Track upload in database if user is authenticated
        if current_user:
            add_upload_record(
                db=db,
                user_id=current_user.id,
                original_filename=file.filename,
                processed_filename=output_filename,
                file_size=len(content)
            )

        # Clean up uploaded file
        os.remove(upload_path)

        # Return CSV file
        return FileResponse(
            path=output_path,
            filename=f"processed_toll_data_"
            f"{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
            media_type="text/csv",
        )

    except Exception as e:
        # Clean up files on error
        if os.path.exists(upload_path):
            os.remove(upload_path)
        raise HTTPException(status_code=500, detail=f"Error processing file: {str(e)}")


@app.get("/processed-files")
async def list_processed_files() -> dict[str, list[str] | int]:
    """List all processed CSV files"""
    try:
        files = [f for f in os.listdir(OUTPUT_DIR) if f.endswith(".csv")]
        return {"files": files, "count": len(files)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing files: {str(e)}")


@app.get("/download/{filename}")
async def download_file(
    filename: str,
    current_user: Optional[User] = Depends(optional_get_current_user),
    db: Session = Depends(get_db)
) -> FileResponse:
    """Download a previously processed CSV file"""
    # If user is authenticated, verify they own this file
    if current_user:
        user_upload = db.query(UploadHistory).filter(
            UploadHistory.user_id == current_user.id,
            UploadHistory.processed_filename == filename
        ).first()
        
        if not user_upload:
            raise HTTPException(status_code=403, detail="Access denied")
    
    file_path = os.path.join(OUTPUT_DIR, filename)
    if not os.path.exists(file_path) or not filename.endswith(".csv"):
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(path=file_path, filename=filename, media_type="text/csv")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
