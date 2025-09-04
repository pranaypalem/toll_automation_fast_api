# Toll Automation FastAPI Microservice

A lightweight FastAPI microservice designed for AWS Lambda deployment that processes toll transaction data from Excel files and returns processed CSV results.

## Features

- 🚀 **AWS Lambda Ready**: Optimized Docker container for serverless deployment
- 📊 **Excel Processing**: Handles `.xlsx`, `.xls`, and `.xlsm` files
- 📈 **Data Processing**: Automated toll transaction data analysis
- 🔒 **File Validation**: 5MB file size limit with format validation  
- 📋 **RESTful API**: Clean FastAPI endpoints with automatic documentation
- 🐳 **Containerized**: Docker image built on AWS Lambda base image
- 🔄 **CI/CD**: Automated deployment pipeline via GitHub Actions

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   S3 Website    │───▶│  API Gateway    │───▶│  AWS Lambda     │
│                 │    │   (Frontend)    │    │   (REST API)    │    │   Function      │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                                                                │
                                                                        ┌─────────────────┐
                                                                        │  Amazon ECR     │
                                                                        │ (Docker Image)  │
                                                                        └─────────────────┘
```

## API Endpoints

### Core Endpoints

- `GET /api` - API health check
- `GET /health` - Detailed health status with timestamp
- `POST /process-toll-data` - Upload and process Excel files
- `GET /processed-files` - List all processed CSV files
- `GET /download/{filename}` - Download processed CSV files

### API Documentation
- Swagger UI: `https://your-api-url/docs`
- ReDoc: `https://your-api-url/redoc`

## Local Development

### Prerequisites
- Python 3.11+
- Docker
- AWS CLI (for deployment)

### Setup

1. **Clone the repository**
```bash
git clone https://github.com/pranaypalem/toll_automation_fast_api.git
cd toll_automation_fast_api
```

2. **Install dependencies**
```bash
pip install -r requirements.txt
```

3. **Run locally**
```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

4. **Test the API**
```bash
curl http://localhost:8000/health
```

## Docker Deployment

### Build locally
```bash
docker build -t toll-automation-lambda .
```

### Test locally
```bash
docker run -p 9000:8080 toll-automation-lambda
```

## AWS Lambda Deployment

### Automatic Deployment (GitHub Actions)
1. Push to `main` branch triggers automatic deployment
2. Docker image built and pushed to ECR
3. Lambda function updated automatically

### Manual Deployment

1. **Create ECR Repository**
```bash
aws ecr create-repository --repository-name toll-automation-lambda --region us-east-1
```

2. **Build and Push Image**
```bash
# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin {account-id}.dkr.ecr.us-east-1.amazonaws.com

# Build and tag
docker build -t toll-automation-lambda .
docker tag toll-automation-lambda:latest {account-id}.dkr.ecr.us-east-1.amazonaws.com/toll-automation-lambda:latest

# Push
docker push {account-id}.dkr.ecr.us-east-1.amazonaws.com/toll-automation-lambda:latest
```

3. **Create Lambda Function**
```bash
aws lambda create-function \
  --function-name toll-automation-lambda \
  --package-type Image \
  --code ImageUri={account-id}.dkr.ecr.us-east-1.amazonaws.com/toll-automation-lambda:latest \
  --role arn:aws:iam::{account-id}:role/lambda-execution-role \
  --timeout 30 \
  --memory-size 512
```

## Configuration

### Environment Variables
- `AWS_REGION`: AWS region (default: us-east-1)
- `ECR_REPOSITORY`: ECR repository name (default: toll-automation-lambda)

### GitHub Secrets Required
- `AWS_ACCESS_KEY_ID`: AWS access key for deployment
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key for deployment

## File Processing

### Supported Formats
- Excel files: `.xlsx`, `.xls`, `.xlsm`
- Maximum file size: 5MB

### Processing Flow
1. Upload Excel file via POST `/process-toll-data`
2. File validation (format, size)
3. Data processing using pandas
4. CSV generation with processed results
5. Return downloadable CSV file

## CI/CD Pipeline

### Backend Deployment (Lambda)
The `deploy-lambda.yml` workflow automatically:
1. Builds Docker image on push to main
2. Pushes image to Amazon ECR
3. Updates Lambda function with new image
4. Triggers on backend code changes

### Frontend Deployment (S3)
The `deploy-frontend.yml` workflow automatically:
1. Deploys frontend files to S3 on changes to `frontend/` directory
2. Updates the static website hosting
3. Can be triggered manually via workflow_dispatch
4. Keeps frontend deployment separate from backend

### Live Deployment
- 🌐 **Website**: http://toll-automation-frontend-9713.s3-website-us-east-1.amazonaws.com
- 🔌 **API**: https://097ytjiafd.execute-api.us-east-1.amazonaws.com/prod

## Project Structure

```
toll_automation_fast_api/
├── frontend/
│   └── index.html           # Beautiful web interface
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   └── toll_processor.py    # Data processing logic
├── .github/
│   └── workflows/
│       ├── deploy-lambda.yml    # Backend CI/CD pipeline
│       └── deploy-frontend.yml  # Frontend CI/CD pipeline
├── lambda_handler.py        # AWS Lambda entry point
├── requirements.txt         # Production dependencies
├── Dockerfile              # Lambda-optimized container
├── aws-setup-guide.md      # Infrastructure setup guide
└── README.md
```

## Dependencies

Core production dependencies:
- `fastapi==0.104.1` - Web framework
- `python-multipart==0.0.6` - File upload support
- `pandas==2.1.3` - Data processing
- `openpyxl==3.1.2` - Excel file handling
- `mangum==0.17.0` - ASGI adapter for Lambda

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Create an issue in this repository
- Check the API documentation at `/docs` endpoint
- Review CloudWatch logs for Lambda function debugging