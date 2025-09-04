# AWS Infrastructure Setup Guide

Follow these steps to set up your complete toll automation solution.

## Prerequisites

1. **Configure AWS CLI** (if not done already):
```bash
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key  
- Default region: `us-east-1`
- Default output format: `json`

## Step 1: Create Lambda Function

```bash
# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"

# Create IAM role for Lambda (if it doesn't exist)
aws iam create-role --role-name lambda-toll-automation-role --assume-role-policy-document '{
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
}'

# Attach basic execution policy
aws iam attach-role-policy --role-name lambda-toll-automation-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Wait for role to propagate
sleep 10

# Create Lambda function
aws lambda create-function \
  --function-name toll-automation \
  --package-type Image \
  --code ImageUri=332210541178.dkr.ecr.us-east-1.amazonaws.com/toll_automation:latest \
  --role arn:aws:iam::$ACCOUNT_ID:role/lambda-toll-automation-role \
  --timeout 30 \
  --memory-size 512 \
  --region us-east-1
```

## Step 2: Create API Gateway

```bash
# Create REST API
API_ID=$(aws apigateway create-rest-api --name toll-automation-api --region us-east-1 --query 'id' --output text)
echo "API ID: $API_ID"

# Get root resource ID
ROOT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region us-east-1 --query 'items[0].id' --output text)

# Create /process-toll-data resource
RESOURCE_ID=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_RESOURCE_ID --path-part "process-toll-data" --region us-east-1 --query 'id' --output text)

# Add POST method
aws apigateway put-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method POST --authorization-type NONE --region us-east-1

# Add CORS support
aws apigateway put-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method OPTIONS --authorization-type NONE --region us-east-1

# Set up Lambda integration
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:$ACCOUNT_ID:function:toll-automation/invocations \
  --region us-east-1

# Add Lambda permission for API Gateway
aws lambda add-permission \
  --function-name toll-automation \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn arn:aws:execute-api:us-east-1:$ACCOUNT_ID:$API_ID/*/*arn \
  --region us-east-1

# Deploy API
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --region us-east-1

# Your API URL
API_URL="https://$API_ID.execute-api.us-east-1.amazonaws.com/prod"
echo "API Gateway URL: $API_URL"
```

## Step 3: Create S3 Bucket for Frontend

```bash
# Generate unique bucket name
BUCKET_NAME="toll-automation-frontend-$RANDOM"
echo "Bucket name: $BUCKET_NAME"

# Create bucket
aws s3 mb s3://$BUCKET_NAME --region us-east-1

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME --index-document index.html

# Create bucket policy file
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
        }
    ]
}
EOF

# Apply bucket policy
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://bucket-policy.json

# Upload frontend files
aws s3 sync frontend/ s3://$BUCKET_NAME/ --delete

# Your website URL
WEBSITE_URL="http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
echo "Website URL: $WEBSITE_URL"

# Clean up
rm bucket-policy.json
```

## Step 4: Update Frontend with API URL

```bash
# Update the frontend file with your API URL
sed -i "s|https://your-api-gateway-url.amazonaws.com/prod|$API_URL|g" frontend/index.html

# Re-upload updated frontend
aws s3 cp frontend/index.html s3://$BUCKET_NAME/index.html
```

## Step 5: Test Your Setup

1. **Test API directly**:
```bash
curl -X POST "$API_URL/health"
```

2. **Visit your website**:
Open the website URL in your browser and test file upload.

## Summary

After running all steps, you'll have:
- ✅ Lambda function running your toll processing code
- ✅ API Gateway providing HTTP endpoints
- ✅ S3 website hosting your beautiful frontend
- ✅ Complete end-to-end file processing workflow

## Troubleshooting

If you get errors:
1. **Invalid credentials**: Run `aws configure` again
2. **Role doesn't exist**: Wait 30 seconds and retry Lambda creation
3. **Permission denied**: Check your IAM user has necessary permissions
4. **API Gateway errors**: Make sure Lambda function exists first

## Optional: CloudFront (for HTTPS)

Once everything works, you can set up CloudFront:
```bash
# Create CloudFront distribution (takes ~15 minutes)
aws cloudfront create-distribution --distribution-config file://cloudfront-config.json
```

---

**🎉 Once complete, you'll have the same beautiful toll processing website, but now running on AWS Lambda!**