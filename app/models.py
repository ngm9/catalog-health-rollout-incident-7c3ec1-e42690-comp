from typing import Literal

from pydantic import BaseModel, Field


class LiveResponse(BaseModel):
    status: Literal["alive"]


class ReadyResponse(BaseModel):
    status: Literal["ready", "not_ready"]
    dependency: Literal["catalog_store"] | None = None


class CatalogSummaryResponse(BaseModel):
    service: str = Field(min_length=1)
    market: str = Field(min_length=2)
    status: Literal["available"]
    product_count: int = Field(ge=0)
