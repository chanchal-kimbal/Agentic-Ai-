#!/bin/bash

set -e

echo "🧪 Running tests..."

# Check if required tools are installed
command -v python >/dev/null 2>&1 || { echo "❌ Python is not installed. Aborting." >&2; exit 1; }

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python -m venv venv
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
pip install pytest pytest-cov flake8 black isort

# Run linting
echo "🔍 Running linting..."
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics --exclude=venv,env,__pycache__,.git,.tox,dist,build,*egg-info
flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics --exclude=venv,env,__pycache__,.git,.tox,dist,build,*egg-info

# Run code formatting check
echo "🎨 Checking code formatting..."
black --check .
isort --check-only .

# Run tests
echo "🧪 Running unit tests..."
pytest --cov=. --cov-report=html --cov-report=term-missing

echo "✅ All tests completed!"

