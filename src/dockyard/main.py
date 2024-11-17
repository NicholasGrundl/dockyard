from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI()

@app.get("/health")
async def health_check() -> dict[str, str]:
    return {
        "service" : "dockyard",
        "status": "ok"
    }


@app.get("/")
async def root()-> dict[str, str]:
    return HTMLResponse(content="<h1>Welcome to Dockyard</h1>", status_code=200)


@app.get("/v1/{username}")
async def greet_user(username: str):
    return {"message": f"Hello {username}"}