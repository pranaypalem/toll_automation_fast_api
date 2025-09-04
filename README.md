# Toll Automation FastAPI

[![Deploy Lambda Function](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-lambda.yml/badge.svg?branch=main)](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-lambda.yml)

[![Deploy Frontend to S3](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-frontend.yml/badge.svg?branch=main)](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-frontend.yml)

A serverless web application that processes toll transaction data from Excel files with user authentication, persistent storage, and automated deployment. Transform your toll data into organized CSV reports with secure cloud processing.

## 🚀 Live Application

- **🌐 Website (HTTPS)**: [d14g7eqts71yui.cloudfront.net](https://d14g7eqts71yui.cloudfront.net/)
- **🌐 Website (HTTP)**: [toll-automation-frontend-9713.s3-website-us-east-1.amazonaws.com](http://toll-automation-frontend-9713.s3-website-us-east-1.amazonaws.com)

The application is served through AWS CloudFront CDN for improved performance, security (HTTPS), and global content delivery. The S3 website provides direct HTTP access for development purposes.

## ✨ Features

- 🔐 **User Authentication**: Secure login system with JWT tokens
- 📊 **Excel Processing**: Handles `.xlsx`, `.xls`, `.xlsm` files and HTML/XML formats
- ☁️ **S3 Storage**: Persistent file storage with presigned download URLs
- 📚 **Upload History**: Track processing history with file management
- 🚀 **Serverless**: AWS Lambda + API Gateway + S3 + CloudFront
- 🔄 **Auto Deployment**: GitHub Actions CI/CD pipeline
- 🌐 **Web Interface**: Responsive frontend with drag-and-drop upload
- 🔒 **Secure Downloads**: Time-limited presigned URLs for file access

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

## 🛠️ Local Development

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

## 🐳 Docker

```bash
# Build
docker build -t toll-automation .

# Test locally
docker run -p 9000:8080 toll-automation
```

## ☁️ Deployment

Push to `main` branch automatically triggers:
1. Docker image build and push to ECR
2. Lambda function update  
3. Frontend deployment to S3

## 🔄 How It Works

1. **Sign up** or **login** to access the secure platform
2. **Upload** Excel files via drag-and-drop or file selection
3. **Process** data automatically with format detection
4. **Store** results securely in AWS S3 cloud storage
5. **Download** processed CSV files with time-limited secure links
6. **Track** upload history and manage your processed files

## 📁 Project Structure

```
toll_automation_fast_api/
├── app/
│   ├── main.py              # FastAPI application & API routes
│   ├── auth.py              # JWT authentication & user management
│   ├── database.py          # SQLAlchemy models & database operations
│   ├── models.py            # Pydantic request/response models
│   ├── s3_service.py        # AWS S3 integration & file storage
│   ├── database_backup.py   # Database persistence for Lambda
│   └── toll_processor.py    # Excel/CSV data processing logic
├── frontend/
│   └── index.html           # Responsive web interface
├── .github/workflows/       # CI/CD pipelines for AWS deployment
├── lambda_handler.py        # AWS Lambda entry point
├── requirements.txt         # Python dependencies
└── Dockerfile              # Lambda container configuration
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

## 🆘 Support

For issues and questions, create an issue in this repository.