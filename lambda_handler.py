import json
import logging
from mangum import Mangum
from app.main import app

logger = logging.getLogger(__name__)

# Create the Mangum handler for AWS Lambda
handler = Mangum(app, lifespan="off")

def lambda_handler(event, context):
    """
    AWS Lambda entry point
    Uses Mangum to adapt FastAPI for Lambda
    """
    # Debug API Gateway binary handling
    logger.info(f"API Gateway isBase64Encoded: {event.get('isBase64Encoded', False)}")
    content_type = event.get('headers', {}).get('content-type', 'unknown')
    logger.info(f"Content-Type header: {content_type}")
    
    return handler(event, context)