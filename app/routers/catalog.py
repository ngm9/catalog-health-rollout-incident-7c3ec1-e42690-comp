from fastapi import APIRouter, Depends

from app.models import CatalogSummaryResponse
from app.settings import Settings, get_settings

router = APIRouter(prefix="/catalog", tags=["catalog"])


@router.get("/summary", response_model=CatalogSummaryResponse)
async def catalog_summary(
    settings: Settings = Depends(get_settings),
) -> CatalogSummaryResponse:
    return CatalogSummaryResponse(
        service=settings.service_name,
        market=settings.catalog_market,
        status="available",
        product_count=128,
    )
