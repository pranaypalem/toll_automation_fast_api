from mangum import Mangum
from app.main import app

# Create the Mangum handler for AWS Lambda
handler = Mangum(app, lifespan="off")

def lambda_handler(event, context):
    """
    AWS Lambda entry point
    Uses Mangum to adapt FastAPI for Lambda
    """
    return handler(event, context)