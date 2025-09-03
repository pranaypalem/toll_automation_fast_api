# 🚀 AWS Lambda Manual Deployment Guide

This guide explains how to manually deploy the Toll Automation service to AWS Lambda using container images.

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed locally
- ECR repository access

## 🛠️ Step-by-Step Deployment

### 1. Build Container Locally

```bash
# Clone the repository
git clone <your-repo-url>
cd python-toll-automation

# Build the Docker image
docker build -t toll-automation:latest .
```

### 2. Create ECR Repository

```bash
# Set your AWS account ID and region
export AWS_ACCOUNT_ID="your-account-id"
export AWS_REGION="ap-south-1"
export ECR_REPOSITORY="toll-automation"

# Create ECR repository
aws ecr create-repository \
    --repository-name $ECR_REPOSITORY \
    --region $AWS_REGION
```

### 3. Push Image to ECR

```bash
# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Tag the image
docker tag toll-automation:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
```

### 4. Create Lambda Execution Role

```bash
# Create execution role
aws iam create-role --role-name lambda-container-execution-role \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"Service": "lambda.amazonaws.com"},
                "Action": "sts:AssumeRole"
            }
        ]
    }'

# Attach basic execution policy
aws iam attach-role-policy \
    --role-name lambda-container-execution-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

### 5. Create Lambda Function

```bash
# Create Lambda function from container image
aws lambda create-function \
    --function-name toll-automation-container \
    --package-type Image \
    --code ImageUri=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest \
    --role arn:aws:iam::$AWS_ACCOUNT_ID:role/lambda-container-execution-role \
    --timeout 300 \
    --memory-size 1024 \
    --region $AWS_REGION
```

### 6. Create API Gateway

```bash
# Create HTTP API Gateway
aws apigatewayv2 create-api \
    --name toll-automation-container-api \
    --protocol-type HTTP \
    --target arn:aws:lambda:$AWS_REGION:$AWS_ACCOUNT_ID:function:toll-automation-container \
    --region $AWS_REGION

# Get the API ID from the output and grant permissions
export API_ID="your-api-id-from-above"

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
    --function-name toll-automation-container \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$AWS_REGION:$AWS_ACCOUNT_ID:$API_ID/*/*" \
    --region $AWS_REGION
```

## 🌐 Access Your Service

Your API will be available at:
```
https://YOUR_API_ID.execute-api.ap-south-1.amazonaws.com/
```

## 🔄 Update Deployment

To update the Lambda function with new code:

```bash
# Rebuild and push new image
docker build -t toll-automation:latest .
docker tag toll-automation:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest

# Update Lambda function
aws lambda update-function-code \
    --function-name toll-automation-container \
    --image-uri $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest \
    --region $AWS_REGION
```

## 🧹 Cleanup

To remove all resources:

```bash
# Delete Lambda function
aws lambda delete-function --function-name toll-automation-container --region $AWS_REGION

# Delete API Gateway
aws apigatewayv2 delete-api --api-id $API_ID --region $AWS_REGION

# Delete IAM role
aws iam detach-role-policy --role-name lambda-container-execution-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role --role-name lambda-container-execution-role

# Delete ECR repository
aws ecr delete-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION --force
```

## ⚙️ Configuration

The service is configured for:
- **Region**: ap-south-1 (Mumbai, India)
- **Memory**: 1024 MB
- **Timeout**: 300 seconds (5 minutes)
- **File Size Limit**: 5 MB
- **Runtime**: Python 3.11 container

## 🔍 Troubleshooting

- **Container fails to start**: Check CloudWatch logs at `/aws/lambda/toll-automation-container`
- **Function timeout**: Increase timeout or memory allocation
- **Permission errors**: Verify IAM roles and API Gateway permissions
- **Image too large**: Optimize Dockerfile or use ECR compression