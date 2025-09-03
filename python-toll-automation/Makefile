# Toll Automation FastAPI - Development Makefile

.PHONY: help install install-dev format lint test type-check security-check ci run build clean docker-test

help: ## Show this help message
	@echo "Toll Automation FastAPI - Development Commands"
	@echo "=============================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install production dependencies
	pip install -r requirements.txt

install-dev: ## Install development dependencies
	pip install -r requirements.txt
	pip install -r requirements-dev.txt

format: ## Format code with black and isort
	@echo "🎨 Formatting code..."
	black app/ tests/
	isort app/ tests/
	@echo "✅ Code formatted"

lint: ## Run linting checks
	@echo "🔍 Running linting checks..."
	flake8 app/ tests/ --max-line-length=88 --extend-ignore=E203,W503
	@echo "✅ Linting passed"

type-check: ## Run type checking
	@echo "📋 Running type checks..."
	mypy app/ --ignore-missing-imports
	@echo "✅ Type checking passed"

test: ## Run tests
	@echo "🧪 Running tests..."
	pytest tests/ -v
	@echo "✅ Tests passed"

security-check: ## Run security checks
	@echo "🔒 Running security checks..."
	pip install bandit
	bandit -r app/ -f json -o bandit-report.json
	@echo "✅ Security check completed"

ci: format lint type-check test security-check ## Run all CI checks locally
	@echo "🎉 All CI checks passed!"

run: ## Run development server
	@echo "🚀 Starting development server..."
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

build: ## Build Docker image
	@echo "🔨 Building Docker image..."
	docker build -t toll-automation:latest .
	@echo "✅ Docker image built"

docker-test: build ## Test Docker container locally
	@echo "🧪 Testing Docker container..."
	docker run --rm -p 9000:8080 toll-automation:latest &
	sleep 5
	curl -f http://localhost:9000/health || (echo "❌ Container test failed" && exit 1)
	@echo "✅ Container test passed"

clean: ## Clean up build artifacts
	@echo "🧹 Cleaning up..."
	find . -type d -name "__pycache__" -delete
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "bandit-report.json" -delete
	@echo "✅ Clean up completed"

# Development workflow examples:
# make install-dev  # Install all dependencies
# make ci           # Run full CI suite locally
# make run          # Start development server
# make docker-test  # Test container build