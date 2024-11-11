from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
async def health_check() -> dict[str, str]:
    return {
        "status": "ok",
    }

@app.get("/")
async def root()-> dict[str, str]:
    return {"status": "ok"}


@app.get("/v1/{username}")
async def greet_user(username: str):
    return {"message": f"Hello {username}"}