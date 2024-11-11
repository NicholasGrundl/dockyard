# Dockyard backend API

## Overview/Welcome

Welcome to the backend service API. This is a FastAPI-based API service providing protected routes to use in the web app

### File Structure

```
backend/
├── app/
│   ├── __init__.py
│   └── main.py
├── Dockerfile
├── requirements.txt
├── requirements-dev.txt
└── README.md
```

### Main Files and Folders

- `app/`: Contains the main application code
  - `main.py`: Entry point of the FastAPI application
- `Dockerfile`: Used to build the Docker image for this service
- `requirements.txt`: Production dependencies
- `requirements-dev.txt`: Development dependencies

## First-time here

### Prerequisites

- Miniconda
- Python 3.9+
- Docker (for containerized development and deployment)

### Setup Instructions

0. Activate conda env
   ```
   conda activate dockyard
   ```

1. Install dependencies:
   ```
   pip install -r requirements.txt
   pip install -r requirements-dev.txt
   ```

2. Run the backend service:
   ```
   uvicorn app.main:app --reload
   ```

The API will be available at `http://localhost:8000`.

### API Endpoints

- `GET /`: Returns a "Hello World" message
- `GET /api/{username}`: Returns a greeting for the specified username

For a complete list of endpoints, visit the Swagger UI documentation at `http://localhost:8000/docs` when the server is running.

## Experienced user

### Development Best Practices

1. Follow PEP 8 style guide for Python code.
2. Write unit tests for new features and ensure all tests pass before committing.
3. Use type hints to improve code readability and catch potential type-related errors.

### Testing

[ TODO: add and flesh out]

### Adding New Endpoints

1. Define new routes in `app/main.py` or create new modules for complex features.
2. Use FastAPI decorators to define HTTP methods and routes.
3. Implement the endpoint logic.
4. Add appropriate error handling and input validation.
5. Update the API documentation using FastAPI's built-in support for OpenAPI.

### Environment Variables

These can be set in a `.env` file for local development.

Environment vars:
[...TODO more coming]


