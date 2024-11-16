from fastapi import FastAPI

app = FastAPI()

@app.get("/api/health")
async def health_check() -> dict[str, str]:
    return {
        "service" : "dockyard",
        "status": "ok"
    }


@app.get("/api")
async def root()-> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/v1/{username}")
async def greet_user(username: str):
    return {"message": f"Hello {username}"}