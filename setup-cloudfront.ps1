# CloudFront Setup Script for HTTPS Support
Write-Host "🌐 Setting up CloudFront for HTTPS support..." -ForegroundColor Green

$S3_BUCKET = "toll-automation-frontend-9713"
$S3_DOMAIN = "$S3_BUCKET.s3-website-us-east-1.amazonaws.com"

# Create CloudFront distribution configuration
$CLOUDFRONT_CONFIG = @"
{
    "CallerReference": "toll-automation-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    "Comment": "Toll Automation Frontend - HTTPS Distribution",
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$S3_BUCKET",
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        }
    },
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$S3_BUCKET",
                "DomainName": "$S3_DOMAIN",
                "CustomOriginConfig": {
                    "HTTPPort": 80,
                    "HTTPSPort": 443,
                    "OriginProtocolPolicy": "http-only"
                }
            }
        ]
    },
    "Enabled": true,
    "DefaultRootObject": "index.html",
    "PriceClass": "PriceClass_100"
}
"@

Write-Host "📝 Creating CloudFront distribution..." -ForegroundColor Yellow
$CLOUDFRONT_CONFIG | Out-File -FilePath "cloudfront-config.json" -Encoding UTF8

try {
    # Create CloudFront distribution
    $RESULT = aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --output json
    $DISTRIBUTION = $RESULT | ConvertFrom-Json
    
    $DISTRIBUTION_ID = $DISTRIBUTION.Distribution.Id
    $CLOUDFRONT_DOMAIN = $DISTRIBUTION.Distribution.DomainName
    
    Write-Host "✅ CloudFront distribution created!" -ForegroundColor Green
    Write-Host "📋 Details:" -ForegroundColor Yellow
    Write-Host "  Distribution ID: $DISTRIBUTION_ID"
    Write-Host "  CloudFront Domain: $CLOUDFRONT_DOMAIN"
    Write-Host "  HTTPS URL: https://$CLOUDFRONT_DOMAIN"
    Write-Host ""
    Write-Host "⏳ Note: CloudFront deployment takes 10-15 minutes to complete globally."
    Write-Host "   Check status: aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status'"
    
    # Clean up
    Remove-Item "cloudfront-config.json"
    
    Write-Host "🎉 Setup complete! Your secure HTTPS website will be available at:" -ForegroundColor Green
    Write-Host "   https://$CLOUDFRONT_DOMAIN" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Error creating CloudFront distribution: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 You can also set up CloudFront via AWS Console:" -ForegroundColor Yellow
    Write-Host "   1. Go to CloudFront Console"
    Write-Host "   2. Create Distribution"
    Write-Host "   3. Origin: $S3_DOMAIN"
    Write-Host "   4. Viewer Protocol Policy: Redirect HTTP to HTTPS"
    Remove-Item "cloudfront-config.json" -ErrorAction SilentlyContinue
}