import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_read_main():
    """Test the main page returns HTML"""
    response = client.get("/")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    assert "Toll Transaction Processor" in response.text

def test_health_check():
    """Test health endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data

def test_api_root():
    """Test API root endpoint"""
    response = client.get("/api")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Toll Automation API is running"

def test_docs_endpoint():
    """Test API documentation is accessible"""
    response = client.get("/docs")
    assert response.status_code == 200

def test_process_toll_data_no_file():
    """Test toll data processing endpoint without file"""
    response = client.post("/process-toll-data")
    assert response.status_code == 422  # Unprocessable Entity

def test_process_toll_data_invalid_file_type():
    """Test toll data processing with invalid file type"""
    response = client.post(
        "/process-toll-data",
        files={"file": ("test.txt", b"test content", "text/plain")}
    )
    assert response.status_code == 400
    assert "Excel file" in response.json()["detail"]

def test_process_toll_data_large_file():
    """Test toll data processing with file too large"""
    large_content = b"x" * (6 * 1024 * 1024)  # 6MB file
    response = client.post(
        "/process-toll-data",
        files={"file": ("test.xlsx", large_content, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")}
    )
    assert response.status_code == 413
    assert "5MB" in response.json()["detail"]