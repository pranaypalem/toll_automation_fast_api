# Use AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.11

# Copy requirements first for better caching
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install Python dependencies
RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Copy application code
COPY app/ ${LAMBDA_TASK_ROOT}/app/
COPY templates/ ${LAMBDA_TASK_ROOT}/templates/
COPY lambda_handler.py ${LAMBDA_TASK_ROOT}

# Create necessary directories
RUN mkdir -p ${LAMBDA_TASK_ROOT}/uploads ${LAMBDA_TASK_ROOT}/outputs

# Set the CMD to your handler
CMD ["lambda_handler.lambda_handler"]