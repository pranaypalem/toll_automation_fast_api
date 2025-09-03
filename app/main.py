import os
import uuid
from datetime import datetime

from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.responses import FileResponse, HTMLResponse, Response
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from .toll_processor import TollProcessor

app = FastAPI(
    title="Toll Automation API",
    description="A FastAPI service for processing toll transaction data",
    version="1.0.0",
)

UPLOAD_DIR = "uploads"
OUTPUT_DIR = "outputs"

# Ensure directories exist
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Setup templates and static files
templates_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
templates = Jinja2Templates(directory=templates_dir)

static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")


@app.get("/", response_class=HTMLResponse)
async def home(request: Request) -> Response:
    """Serve the main frontend page"""
    return templates.TemplateResponse("index.html", {"request": request})


@app.get("/api")
async def root() -> dict[str, str]:
    return {"message": "Toll Automation API is running"}


@app.get("/health")
async def health_check() -> dict[str, str]:
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


@app.post("/process-toll-data")
async def process_toll_data(file: UploadFile = File(...)) -> FileResponse:
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

        # Process the file
        processor = TollProcessor()
        processed_data = processor.process_excel_file(upload_path)

        # Save as CSV
        output_filename = f"processed_toll_data_{file_id}.csv"
        output_path = os.path.join(OUTPUT_DIR, output_filename)
        processed_data.to_csv(output_path, index=False)

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
async def download_file(filename: str) -> FileResponse:
    """Download a previously processed CSV file"""
    file_path = os.path.join(OUTPUT_DIR, filename)
    if not os.path.exists(file_path) or not filename.endswith(".csv"):
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(path=file_path, filename=filename, media_type="text/csv")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
