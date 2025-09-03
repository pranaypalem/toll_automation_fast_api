# Toll Automation FastAPI Service

A Python FastAPI microservice implementation of the VBA toll automation functionality. Processes toll transaction data from Excel files and outputs CSV reports.

## Features

- **FastAPI REST API**: Modern, fast web framework with automatic API documentation
- **Excel Processing**: Handles .xlsx, .xls, and .xlsm files using pandas and openpyxl
- **Data Transformation**: Replicates the VBA automation workflow:
  - Filters debit transactions > 0
  - Groups up to 8 entries per day
  - Combines toll routes and sums amounts
  - Standardizes date formats (dd/mm/yyyy)
- **CSV Output**: Returns processed data as downloadable CSV files
- **Docker Support**: Ready for containerized deployment
- **File Management**: Upload and download endpoints for file handling

## Quick Start

### Local Development

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the server:**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

3. **Access the API:**
   - API: http://localhost:8000
   - Interactive docs: http://localhost:8000/docs
   - Alternative docs: http://localhost:8000/redoc

### Docker Deployment

1. **Build and run with Docker Compose:**
   ```bash
   docker-compose up --build
   ```

2. **Or build and run manually:**
   ```bash
   docker build -t toll-automation .
   docker run -p 8000:8000 toll-automation
   ```

## API Endpoints

### POST `/process-toll-data`
Upload and process a toll transaction Excel file.

**Request:**
- File upload: Excel file (.xlsx, .xls, .xlsm)

**Response:**
- CSV file download with processed data

### GET `/health`
Health check endpoint.

### GET `/processed-files`
List all processed CSV files.

### GET `/download/{filename}`
Download a specific processed CSV file.

## Data Processing Workflow

The service follows the same workflow as the original VBA automation:

1. **Import Data**: Load Excel file and validate required columns
2. **Filter Data**: Keep only debit transactions with amount > 0
3. **Format Data**: 
   - Group transactions by date (max 8 per day)
   - Combine transaction IDs (last 4 digits)
   - Sum amounts for grouped transactions
4. **Convert Dates**: Standardize to dd/mm/yyyy format
5. **Final Output**: Create CSV with columns:
   - Toll Route (combined transaction IDs)
   - Total Amount
   - Date

## Required Excel Columns

The input Excel file must contain these columns:
- `AMOUNT IN RS`
- `TRANSACTIONTYPE` 
- `TRANSACTION_DATE`
- `TRANSACTIONID`

## Project Structure

```
python-toll-automation/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   └── toll_processor.py    # Core processing logic
├── uploads/                 # Temporary file uploads
├── outputs/                 # Processed CSV files
├── tests/                   # Test files
├── requirements.txt         # Python dependencies
├── Dockerfile              # Container configuration
├── docker-compose.yml      # Docker Compose setup
└── README.md               # This file
```

## Development

### Adding Tests
```bash
pytest tests/
```

### Code Style
```bash
black app/
flake8 app/
```

## Deployment Considerations

- Configure proper file cleanup policies for uploads/outputs directories
- Set appropriate file size limits for uploads
- Configure logging and monitoring
- Use environment variables for configuration
- Consider using a reverse proxy (nginx) for production