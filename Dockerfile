# AWS Lambda compatible Docker image for toll automation microservice
# Optimized for Lambda deployment with minimal size

# Use AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.11

# Install system dependencies if needed
RUN yum update -y && yum clean all

# Copy requirements and install Python dependencies
COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ${LAMBDA_TASK_ROOT}/app/
COPY lambda_handler.py ${LAMBDA_TASK_ROOT}

# Note: Lambda will create /tmp directories at runtime

# Set environment variables
ENV PYTHONPATH="${LAMBDA_TASK_ROOT}"
ENV PYTHONUNBUFFERED=1

# Set the Lambda handler
CMD ["lambda_handler.lambda_handler"]