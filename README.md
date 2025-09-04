# Toll Automation FastAPI

[![ECR Deployment CI/CD](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-lambda.yml/badge.svg)](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-lambda.yml)

[![Frontend CI/CD](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-frontend.yml/badge.svg)](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-frontend.yml)

A production-ready serverless application that processes toll transaction data from Excel files and returns processed CSV results. Built with FastAPI and deployed on AWS Lambda.

## 🚀 Live Application

- **🌐 Website**: [toll-automation-frontend-9713.s3-website-us-east-1.amazonaws.com](http://toll-automation-frontend-9713.s3-website-us-east-1.amazonaws.com)
- **🔌 API**: [097ytjiafd.execute-api.us-east-1.amazonaws.com/prod](https://097ytjiafd.execute-api.us-east-1.amazonaws.com/prod)

## ✨ Features

- 🚀 **Serverless Architecture**: AWS Lambda + API Gateway + S3
- 📊 **Excel Processing**: Handles `.xlsx`, `.xls`, and `.xlsm` files (up to 5MB)
- 🔧 **Binary File Support**: Properly configured API Gateway for Excel uploads
- 📋 **RESTful API**: FastAPI with automatic OpenAPI documentation
- 🐳 **Containerized**: Docker deployment to AWS Lambda
- 🔄 **CI/CD Pipeline**: Automated deployment via GitHub Actions
- 🌐 **Modern Frontend**: Clean, responsive web interface

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│   S3 Website    │───▶│  API Gateway    │───▶│  AWS Lambda     │
│                 │    │   (Frontend)    │    │   (REST API)    │    │   Function      │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │                        │
                                                ┌─────────────────┐    ┌─────────────────┐
                                                │ CloudFront CDN  │    │  Amazon ECR     │
                                                │    (HTTPS)      │    │ (Docker Image)  │
                                                └─────────────────┘    └─────────────────┘
```

## 📡 API Endpoints

### Core Endpoints
- `GET /api` - API health check
- `GET /health` - Detailed health status with timestamp
- `POST /process-toll-data` - Upload and process Excel files
- `GET /processed-files` - List all processed CSV files
- `GET /download/{filename}` - Download processed CSV files

### API Documentation
- **Swagger UI**: `https://097ytjiafd.execute-api.us-east-1.amazonaws.com/prod/docs`
- **ReDoc**: `https://097ytjiafd.execute-api.us-east-1.amazonaws.com/prod/redoc`

## 🛠️ Local Development

### Prerequisites
- Python 3.11+
- Docker Desktop
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

## 🐳 Docker

### Build and Test Locally
```bash
# Build
docker build -t toll-automation .

# Test locally
docker run -p 9000:8080 toll-automation
```

## ☁️ AWS Deployment

### Automated CI/CD
Push to `main` branch automatically triggers:
1. Docker image build and push to ECR
2. Lambda function update
3. Frontend deployment to S3 (if frontend files changed)

### Manual Deployment
See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for manual deployment instructions.

## 📁 Project Structure

```
toll_automation_fast_api/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   └── toll_processor.py    # Data processing logic
├── frontend/
│   └── index.html           # Web interface
├── docs/
│   └── DEPLOYMENT.md        # Deployment guide
├── .github/workflows/
│   ├── deploy-lambda.yml    # Backend CI/CD
│   └── deploy-frontend.yml  # Frontend CI/CD
├── uploads/                 # File uploads (temporary)
├── outputs/                 # Processed files (temporary)
├── lambda_handler.py        # AWS Lambda entry point
├── requirements.txt         # Dependencies
├── Dockerfile              # Lambda container
└── README.md
```

## 📦 Dependencies

### Core Production Dependencies
```
fastapi==0.104.1          # Web framework
python-multipart==0.0.6   # File upload support
pandas==2.1.3             # Data processing
openpyxl==3.1.2           # Excel file handling (.xlsx)
xlrd==2.0.1               # Excel file handling (.xls)
mangum==0.17.0            # ASGI adapter for Lambda
```

## 🔧 Configuration

### AWS Resources
- **Region**: `us-east-1`
- **Lambda Function**: `toll-automation`
- **API Gateway**: `toll-automation-api`
- **ECR Repository**: `toll_automation`
- **S3 Bucket**: `toll-automation-frontend-9713`

### GitHub Secrets (Required for CI/CD)
- `AWS_ACCESS_KEY_ID`: AWS access key for deployment
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key for deployment

### API Gateway Binary Media Types
The API Gateway is configured to handle these binary media types:
- `multipart/form-data`
- `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- `application/vnd.ms-excel`

## 🔄 Processing Flow

1. **Upload**: User uploads Excel file via web interface
2. **Validation**: File format and size validation (max 5MB)
3. **Processing**: Pandas-based data processing
4. **Output**: Generated CSV file available for download
5. **Cleanup**: Temporary files automatically cleaned up

## 🚀 Performance

- **Cold Start**: ~2-3 seconds
- **Warm Requests**: ~500ms
- **Memory Usage**: 512MB Lambda allocation
- **Timeout**: 30 seconds
- **File Limit**: 5MB per upload

## 🛡️ Security Features

- File type validation
- File size limits
- Temporary file cleanup
- HTTPS via CloudFront
- AWS IAM role-based permissions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/pranaypalem/toll_automation_fast_api/issues)
- **API Docs**: [Swagger UI](https://097ytjiafd.execute-api.us-east-1.amazonaws.com/prod/docs)
- **Logs**: AWS CloudWatch Logs (`/aws/lambda/toll-automation`)

---

**Made with ❤️ using FastAPI, AWS Lambda, and modern DevOps practices.**