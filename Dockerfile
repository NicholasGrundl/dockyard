FROM python:3.11-slim

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
COPY requirements-build.txt .
RUN pip install --no-cache-dir -r requirements.txt -r requirements-build.txt

# Copy the source code
COPY src/ src/

# Expose port 8000
EXPOSE 8000

# Run the application
CMD ["python", "-m", "uvicorn", "dockyard.main:app", "--host", "0.0.0.0", "--port", "8000"]