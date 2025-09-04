# AWS Infrastructure Setup Script for Toll Automation
# Run this script to set up API Gateway, Lambda function, S3, and CloudFront

Write-Host "🚀 Setting up AWS Infrastructure for Toll Automation..." -ForegroundColor Green

# Configuration
$REGION = "us-east-1"
$LAMBDA_FUNCTION_NAME = "toll-automation"
$API_NAME = "toll-automation-api"
$S3_BUCKET_NAME = "toll-automation-frontend-$(Get-Random)"
$CLOUDFRONT_COMMENT = "Toll Automation Frontend Distribution"

Write-Host "📝 Configuration:" -ForegroundColor Yellow
Write-Host "  Region: $REGION"
Write-Host "  Lambda Function: $LAMBDA_FUNCTION_NAME"
Write-Host "  API Gateway: $API_NAME"
Write-Host "  S3 Bucket: $S3_BUCKET_NAME"

# Step 1: Create Lambda Function (if it doesn't exist)
Write-Host "`n🔧 Step 1: Creating Lambda Function..." -ForegroundColor Blue
$ECR_URI = "332210541178.dkr.ecr.$REGION.amazonaws.com/toll_automation:latest"

try {
    # Check if function exists
    aws lambda get-function --function-name $LAMBDA_FUNCTION_NAME --region $REGION 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Lambda function already exists. Updating..." -ForegroundColor Green
        aws lambda update-function-code --function-name $LAMBDA_FUNCTION_NAME --image-uri $ECR_URI --region $REGION
    } else {
        Write-Host "  🆕 Creating new Lambda function..." -ForegroundColor Yellow
        
        # Create execution role first
        $ROLE_POLICY = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@
        
        $ROLE_POLICY | Out-File -FilePath "lambda-role-policy.json" -Encoding UTF8
        
        aws iam create-role --role-name lambda-toll-automation-role --assume-role-policy-document file://lambda-role-policy.json --region $REGION
        aws iam attach-role-policy --role-name lambda-toll-automation-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole --region $REGION
        
        # Get account ID
        $ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
        $ROLE_ARN = "arn:aws:iam::${ACCOUNT_ID}:role/lambda-toll-automation-role"
        
        # Wait for role to be available
        Start-Sleep -Seconds 10
        
        aws lambda create-function `
            --function-name $LAMBDA_FUNCTION_NAME `
            --package-type Image `
            --code ImageUri=$ECR_URI `
            --role $ROLE_ARN `
            --timeout 30 `
            --memory-size 512 `
            --region $REGION
            
        Remove-Item "lambda-role-policy.json"
    }
    Write-Host "  ✅ Lambda function ready!" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Error with Lambda function: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Create API Gateway
Write-Host "`n🌐 Step 2: Creating API Gateway..." -ForegroundColor Blue

try {
    # Create REST API
    $API_ID = aws apigateway create-rest-api --name $API_NAME --region $REGION --query 'id' --output text
    Write-Host "  📝 API ID: $API_ID" -ForegroundColor Yellow
    
    # Get root resource ID
    $ROOT_RESOURCE_ID = aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[0].id' --output text
    
    # Create /process-toll-data resource
    $RESOURCE_ID = aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_RESOURCE_ID --path-part "process-toll-data" --region $REGION --query 'id' --output text
    
    # Add POST method
    aws apigateway put-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method POST --authorization-type NONE --region $REGION
    
    # Get account ID and set up Lambda integration
    $ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
    $LAMBDA_ARN = "arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_FUNCTION_NAME}"
    
    aws apigateway put-integration `
        --rest-api-id $API_ID `
        --resource-id $RESOURCE_ID `
        --http-method POST `
        --type AWS_PROXY `
        --integration-http-method POST `
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" `
        --region $REGION
    
    # Add Lambda permission for API Gateway
    aws lambda add-permission `
        --function-name $LAMBDA_FUNCTION_NAME `
        --statement-id "apigateway-invoke" `
        --action "lambda:InvokeFunction" `
        --principal "apigateway.amazonaws.com" `
        --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" `
        --region $REGION
    
    # Deploy API
    aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --region $REGION
    
    $API_URL = "https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod"
    Write-Host "  ✅ API Gateway created!" -ForegroundColor Green
    Write-Host "  🔗 API URL: $API_URL" -ForegroundColor Yellow
} catch {
    Write-Host "  ❌ Error with API Gateway: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Create S3 Bucket for Frontend
Write-Host "`n📦 Step 3: Creating S3 Bucket for Frontend..." -ForegroundColor Blue

try {
    # Create bucket
    if ($REGION -eq "us-east-1") {
        aws s3 mb s3://$S3_BUCKET_NAME
    } else {
        aws s3 mb s3://$S3_BUCKET_NAME --region $REGION
    }
    
    # Enable static website hosting
    aws s3 website s3://$S3_BUCKET_NAME --index-document index.html
    
    # Set bucket policy for public read
    $BUCKET_POLICY = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$S3_BUCKET_NAME/*"
        }
    ]
}
"@
    
    $BUCKET_POLICY | Out-File -FilePath "bucket-policy.json" -Encoding UTF8
    aws s3api put-bucket-policy --bucket $S3_BUCKET_NAME --policy file://bucket-policy.json
    Remove-Item "bucket-policy.json"
    
    # Upload frontend files
    aws s3 sync frontend/ s3://$S3_BUCKET_NAME/ --delete
    
    $S3_WEBSITE_URL = "http://${S3_BUCKET_NAME}.s3-website-${REGION}.amazonaws.com"
    Write-Host "  ✅ S3 bucket created and files uploaded!" -ForegroundColor Green
    Write-Host "  🔗 S3 Website URL: $S3_WEBSITE_URL" -ForegroundColor Yellow
} catch {
    Write-Host "  ❌ Error with S3: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Update Frontend with API URL
Write-Host "`n🔄 Step 4: Updating Frontend with API URL..." -ForegroundColor Blue

try {
    $indexContent = Get-Content "frontend/index.html" -Raw
    $updatedContent = $indexContent -replace "https://your-api-gateway-url.amazonaws.com/prod", $API_URL
    $updatedContent | Out-File -FilePath "frontend/index.html" -Encoding UTF8
    
    # Re-upload updated frontend
    aws s3 cp frontend/index.html s3://$S3_BUCKET_NAME/index.html
    
    Write-Host "  ✅ Frontend updated with API URL!" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Error updating frontend: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n🎉 Setup Complete!" -ForegroundColor Green
Write-Host "📋 Summary:" -ForegroundColor Yellow
Write-Host "  Lambda Function: $LAMBDA_FUNCTION_NAME"
Write-Host "  API Gateway URL: $API_URL"
Write-Host "  S3 Website URL: $S3_WEBSITE_URL"
Write-Host "  S3 Bucket: $S3_BUCKET_NAME"

Write-Host "`n📝 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test your API: $API_URL/process-toll-data"
Write-Host "  2. Visit your website: $S3_WEBSITE_URL"
Write-Host "  3. Optionally set up CloudFront for HTTPS and better performance"

Write-Host "`n⚠️  Note: The website is now accessible via HTTP. For production, consider setting up CloudFront with SSL certificate." -ForegroundColor Yellow