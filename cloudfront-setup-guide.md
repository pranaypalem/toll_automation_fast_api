# CloudFront HTTPS Setup Guide

## Why CloudFront?
- **HTTPS Support**: S3 static hosting only supports HTTP
- **Security**: Browsers mark HTTP sites as "Not Secure"
- **Performance**: Global CDN for faster loading
- **Free SSL Certificate**: AWS provides free SSL certificates

## Quick Setup (AWS Console)

### Step 1: Create CloudFront Distribution
1. Go to [CloudFront Console](https://console.aws.amazon.com/cloudfront/)
2. Click **"Create Distribution"**

### Step 2: Configure Origin
- **Origin Domain**: `toll-automation-frontend-9713.s3-website-us-east-1.amazonaws.com`
- **Protocol**: HTTP only (S3 website endpoints don't support HTTPS)

### Step 3: Configure Behavior
- **Viewer Protocol Policy**: **"Redirect HTTP to HTTPS"**
- **Allowed HTTP Methods**: GET, HEAD
- **Cache Policy**: Use default or "Caching Optimized"

### Step 4: Configure Distribution
- **Default Root Object**: `index.html`
- **Price Class**: "Use only North America and Europe" (cheaper)
- **Comment**: "Toll Automation Frontend"

### Step 5: Create Distribution
- Click **"Create Distribution"**
- **Deployment Time**: 10-15 minutes globally
- **Status**: Wait for "Deployed" status

## After Deployment

### Your New HTTPS URLs
- **CloudFront URL**: `https://d1234567890123.cloudfront.net`
- **Custom Domain**: Optional - you can add your own domain later

### Update Frontend (Optional)
If you want to use HTTPS API calls, you might need to update the frontend to use HTTPS endpoints, but it should work fine as-is.

## Testing
1. Wait for CloudFront status to show "Deployed"
2. Visit your HTTPS URL
3. Browser should show secure lock icon
4. Test file upload functionality

## Cost
- **CloudFront**: Free tier includes 1TB data transfer out per month
- **S3**: Minimal costs for storage and requests
- **Lambda**: Only pay for execution time
- **API Gateway**: Free tier includes 1M requests per month

## Troubleshooting
- **504 Errors**: Check S3 bucket policy allows public access
- **403 Errors**: Verify S3 static website hosting is enabled
- **CORS Issues**: These should now be fixed with our Lambda update

---

**Result**: Secure HTTPS website with same functionality! 🚀