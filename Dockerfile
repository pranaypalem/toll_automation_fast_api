# Multi-stage build for minimal image size
# Stage 1: Build dependencies
FROM public.ecr.aws/lambda/python:3.11-x86_64 AS builder

# Install build dependencies
RUN yum update -y && yum install -y gcc

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --target /opt/python -r requirements.txt

# Remove unnecessary files to reduce size
RUN find /opt/python -type d -name "__pycache__" -exec rm -rf {} + || true
RUN find /opt/python -type d -name "*.dist-info" -exec rm -rf {} + || true
RUN find /opt/python -name "*.pyc" -delete || true
RUN find /opt/python -name "*.pyo" -delete || true

# Stage 2: Runtime image (minimal)
FROM public.ecr.aws/lambda/python:3.11-x86_64

# Copy only necessary Python packages from builder
COPY --from=builder /opt/python ${LAMBDA_RUNTIME_DIR}

# Copy application code (minimal set)
COPY app/ ${LAMBDA_TASK_ROOT}/app/
COPY templates/ ${LAMBDA_TASK_ROOT}/templates/
COPY lambda_handler.py ${LAMBDA_TASK_ROOT}/

# Create minimal directory structure
RUN mkdir -p ${LAMBDA_TASK_ROOT}/uploads ${LAMBDA_TASK_ROOT}/outputs

# Remove any leftover cache and temporary files
RUN find ${LAMBDA_TASK_ROOT} -type d -name "__pycache__" -exec rm -rf {} + || true
RUN find ${LAMBDA_TASK_ROOT} -name "*.pyc" -delete || true

# Set the CMD to your handler
CMD ["lambda_handler.lambda_handler"]