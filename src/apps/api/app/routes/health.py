from fastapi import APIRouter

from app.core.version import APP_VERSION

router = APIRouter()


@router.get("/health")
async def get_health() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/version")
async def get_version() -> dict[str, str]:
    return {"version": APP_VERSION}
