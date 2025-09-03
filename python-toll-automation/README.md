# 🚗 Toll Automation FastAPI Service

A containerized FastAPI microservice for processing toll transaction data with automatic deployment to AWS Lambda.

## ✨ Features

- **📄 Excel Processing**: Upload .xlsx/.xls/.xlsm files (max 5MB)
- **🔄 Data Transformation**: 
  - Filters debit transactions > 0
  - Groups up to 8 toll entries per day
  - Combines transaction IDs and calculates totals
  - Standardizes date formats (dd/mm/yyyy)
- **📊 CSV Export**: Download processed data as CSV
- **🌐 Beautiful Web Interface**: Professional frontend with drag & drop
- **☁️ Serverless Deployment**: Runs on AWS Lambda containers
- **🚀 CI/CD**: Automated deployment via GitHub Actions

## 🏗️ Architecture

```
GitHub → GitHub Actions → AWS ECR → AWS Lambda → API Gateway → Users
```

## 🚀 Quick Start

### Local Development

1. **Clone and run:**
   ```bash
   git clone <your-repo-url>
   cd python-toll-automation
   pip install -r requirements.txt
   uvicorn app.main:app --reload
   ```

2. **Visit:** http://localhost:8000

### Production Deployment

1. **Set GitHub Secrets:**
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

2. **Push to main branch:**
   ```bash
   git push origin main
   ```

3. **GitHub Actions will automatically:**
   - Build Docker container
   - Push to ECR
   - Deploy to Lambda
   - Set up API Gateway

## 🌐 Live Service

**URL:** https://[api-id].execute-api.ap-south-1.amazonaws.com/

## 🔧 Configuration

- **Region:** ap-south-1 (Mumbai, India)
- **Runtime:** Python 3.11 container
- **Memory:** 1024 MB
- **Timeout:** 300 seconds
- **File Size Limit:** 5 MB

## 📊 Usage

1. **Visit the web interface**
2. **Drag or click to upload Excel file**
3. **Wait for processing** (progress bar shows status)
4. **Download CSV** automatically starts

## 💰 Cost

- **~₹5-15/month** for 100 requests
- **Free tier:** 1M requests/month for first 12 months

## 🛠️ Development

### Project Structure
```
python-toll-automation/
├── app/
│   ├── main.py              # FastAPI application
│   └── toll_processor.py    # Core processing logic
├── templates/
│   └── index.html          # Web interface
├── .github/workflows/
│   └── deploy.yml          # CI/CD pipeline
├── Dockerfile              # Container configuration
├── requirements.txt        # Python dependencies
└── lambda_handler.py       # AWS Lambda entry point
```

### Required Excel Columns
- `AMOUNT IN RS`
- `TRANSACTIONTYPE`
- `TRANSACTION_DATE`
- `TRANSACTIONID`

## 🔒 Security

- File type validation
- File size limits (5MB)
- Temporary file cleanup
- AWS IAM role-based access