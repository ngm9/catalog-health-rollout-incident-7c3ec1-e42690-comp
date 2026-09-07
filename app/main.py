import asyncio
import logging
from contextlib import asynccontextmanager
from time import monotonic

from fastapi import FastAPI, Request

from app.routers import catalog, health
from app.settings import get_settings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s level=%(levelname)s logger=%(name)s message=%(message)s",
)
logger = logging.getLogger("catalog-api")


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    app.state.dependency_ready = False
    app.state.started_at = monotonic()

    logger.info(
        "service_start service=%s market=%s initialization_seconds=%s",
        settings.service_name,
        settings.catalog_market,
        settings.dependency_init_seconds,
    )

    async def initialize_catalog_dependency() -> None:
        await asyncio.sleep(settings.dependency_init_seconds)
        app.state.dependency_ready = True
        logger.info("catalog_dependency_initialized market=%s", settings.catalog_market)

    initialization_task = asyncio.create_task(initialize_catalog_dependency())
    try:
        yield
    finally:
        initialization_task.cancel()
        try:
            await initialization_task
        except asyncio.CancelledError:
            pass
        logger.info("service_stop service=%s", settings.service_name)


app = FastAPI(
    title="Cartline Catalog API",
    version="1.0.0",
    lifespan=lifespan,
    openapi_tags=[
        {"name": "catalog", "description": "Catalog serving operations"},
        {"name": "health", "description": "Platform health signals"},
    ],
)


@app.middleware("http")
async def request_logging(request: Request, call_next):
    started = monotonic()
    response = await call_next(request)
    elapsed_ms = round((monotonic() - started) * 1000, 2)
    logger.info(
        "request method=%s path=%s status=%s duration_ms=%s",
        request.method,
        request.url.path,
        response.status_code,
        elapsed_ms,
    )
    return response


app.include_router(health.router)
app.include_router(catalog.router, prefix="/v1")
