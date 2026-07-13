import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.requests import Request
from fastapi.responses import JSONResponse

from app.core.exceptions import NotFoundError
from app.core.logging import configure_logging
from app.core.version import APP_VERSION
from app.routes import currencies, health, languages, limits, me

configure_logging()
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    logger.info("ana_api_started")
    yield


app = FastAPI(title="Ana API", version=APP_VERSION, lifespan=lifespan)


@app.exception_handler(NotFoundError)
async def not_found_error_handler(_: Request, exc: NotFoundError) -> JSONResponse:
    return JSONResponse(status_code=404, content={"detail": str(exc)})


app.include_router(health.router)
app.include_router(limits.router)
app.include_router(currencies.router)
app.include_router(languages.router)
app.include_router(me.router)
