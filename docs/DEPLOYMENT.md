# Deployment Guide

## Infrastructure Overview

This application is deployed on AWS using:
- **AWS Lambda**: Serverless compute with container image
- **Amazon ECR**: Container registry for Docker images  
- **API Gateway**: HTTP endpoints with binary media type support
- **S3 + CloudFront**: Static website hosting with HTTPS

## GitHub Actions CI/CD

The repository uses GitHub Actions for automated deployment:
1. Push to `main` branch triggers the workflow
2. Docker image is built and pushed to ECR
3. Lambda function is automatically updated

## Manual Deployment

If needed, you can deploy manually:

```bash
# Build and push Docker image
docker build -t toll-automation .
docker tag toll-automation:latest 332210541178.dkr.ecr.us-east-1.amazonaws.com/toll_automation:latest
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 332210541178.dkr.ecr.us-east-1.amazonaws.com
docker push 332210541178.dkr.ecr.us-east-1.amazonaws.com/toll_automation:latest

# Update Lambda function
aws lambda update-function-code --function-name toll-automation --image-uri 332210541178.dkr.ecr.us-east-1.amazonaws.com/toll_automation:latest --region us-east-1
```

## Environment Configuration

- **Region**: us-east-1
- **Lambda Function**: toll-automation
- **API Gateway**: toll-automation-api
- **ECR Repository**: toll_automation

## Binary Media Types

The API Gateway is configured to handle these binary media types:
- `multipart/form-data`
- `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` 
- `application/vnd.ms-excel`