import logging

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

from app.models import LiveResponse, ReadyResponse

router = APIRouter(prefix="/health", tags=["health"])
logger = logging.getLogger("catalog-api.health")


@router.get("/live", response_model=LiveResponse)
async def live() -> LiveResponse:
    return LiveResponse(status="alive")


@router.get(
    "/ready",
    response_model=ReadyResponse,
    responses={503: {"model": ReadyResponse}},
)
async def ready(request: Request):
    if request.app.state.dependency_ready:
        return ReadyResponse(status="ready")

    logger.warning("readiness_check dependency=catalog_store state=initializing")
    return JSONResponse(
        status_code=500,
        content={"status": "not_ready", "dependency": "catalog_store"},
    )
