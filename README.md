# Toll Automation FastAPI

[![Deploy Lambda Function](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-lambda.yml/badge.svg)](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-lambda.yml)

[![Deploy Frontend to S3](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-frontend.yml/badge.svg)](https://github.com/pranaypalem/toll_automation_fast_api/actions/workflows/deploy-frontend.yml)

A serverless application that processes toll transaction data from Excel files and returns processed CSV results.

## 🚀 Live Application

- **🌐 Website**: [toll-automation-frontend-9713.s3-website-us-east-1.amazonaws.com](http://toll-automation-frontend-9713.s3-website-us-east-1.amazonaws.com)

## ✨ Features

- 📊 **Excel Processing**: Handles `.xlsx`, `.xls`, `.xlsm` files and HTML/XML formats
- 🚀 **Serverless**: AWS Lambda + API Gateway + S3
- 🔄 **Auto Deployment**: GitHub Actions CI/CD pipeline
- 🌐 **Web Interface**: Simple file upload and download

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

1. Upload Excel file via web interface
2. System detects file format (Excel, HTML, CSV, etc.)
3. Processes toll transaction data
4. Returns downloadable CSV file

## 📁 Project Structure

```
toll_automation_fast_api/
├── app/
│   ├── main.py              # FastAPI application
│   └── toll_processor.py    # Data processing logic
├── frontend/
│   └── index.html           # Web interface
├── .github/workflows/       # CI/CD pipelines
├── lambda_handler.py        # AWS Lambda entry point
├── requirements.txt         # Dependencies
└── Dockerfile              # Lambda container
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

## 🆘 Support

For issues and questions, create an issue in this repository.