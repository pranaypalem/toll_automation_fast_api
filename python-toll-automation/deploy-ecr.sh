#!/bin/bash

# Configuration
AWS_ACCOUNT_ID="332210541178"
AWS_REGION="ap-south-1"
ECR_REPOSITORY="toll-automation"
IMAGE_TAG="latest"

echo "🚀 Starting ECR deployment..."

# Step 1: Create ECR repository (if it doesn't exist)
echo "📦 Creating ECR repository..."
aws ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION 2>/dev/null || echo "Repository already exists"

# Step 2: Get ECR login token and authenticate Docker
echo "🔐 Authenticating Docker with ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Step 3: Build Docker image
echo "🔨 Building Docker image..."
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .

# Step 4: Tag image for ECR
echo "🏷️  Tagging image for ECR..."
docker tag $ECR_REPOSITORY:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

# Step 5: Push image to ECR
echo "⬆️  Pushing image to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG

# Step 6: Create or update Lambda function
echo "⚡ Creating Lambda function from container..."

# Check if function exists
if aws lambda get-function --function-name toll-automation-container --region $AWS_REGION >/dev/null 2>&1; then
    echo "📝 Updating existing Lambda function..."
    aws lambda update-function-code \
        --function-name toll-automation-container \
        --image-uri $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG \
        --region $AWS_REGION
else
    echo "🆕 Creating new Lambda function..."
    # Create execution role first
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
        }' 2>/dev/null || echo "Role already exists"
    
    aws iam attach-role-policy \
        --role-name lambda-container-execution-role \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

    sleep 10  # Wait for role propagation
    
    aws lambda create-function \
        --function-name toll-automation-container \
        --package-type Image \
        --code ImageUri=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG \
        --role arn:aws:iam::$AWS_ACCOUNT_ID:role/lambda-container-execution-role \
        --timeout 300 \
        --memory-size 1024 \
        --region $AWS_REGION
fi

# Step 7: Create API Gateway (if needed)
echo "🌐 Setting up API Gateway..."
API_ID=$(aws apigatewayv2 create-api \
    --name toll-automation-container-api \
    --protocol-type HTTP \
    --target arn:aws:lambda:$AWS_REGION:$AWS_ACCOUNT_ID:function:toll-automation-container \
    --region $AWS_REGION \
    --query 'ApiId' --output text 2>/dev/null || \
    aws apigatewayv2 get-apis --region $AWS_REGION --query 'Items[?Name==`toll-automation-container-api`].ApiId' --output text)

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
    --function-name toll-automation-container \
    --statement-id apigateway-invoke-container \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$AWS_REGION:$AWS_ACCOUNT_ID:$API_ID/*/*" \
    --region $AWS_REGION 2>/dev/null || echo "Permission already exists"

echo ""
echo "✅ Deployment complete!"
echo "🌐 Your API URL: https://$API_ID.execute-api.$AWS_REGION.amazonaws.com/"
echo ""