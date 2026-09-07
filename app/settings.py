import os
from dataclasses import dataclass
from functools import lru_cache


@dataclass(frozen=True)
class Settings:
    service_name: str
    catalog_market: str
    dependency_init_seconds: float


@lru_cache
def get_settings() -> Settings:
    raw_delay = os.getenv("DEPENDENCY_INIT_SECONDS", "4")
    try:
        dependency_init_seconds = max(0.0, float(raw_delay))
    except ValueError:
        dependency_init_seconds = 4.0

    return Settings(
        service_name=os.getenv("SERVICE_NAME", "catalog-api"),
        catalog_market=os.getenv("CATALOG_MARKET_NAME", "unknown"),
        dependency_init_seconds=dependency_init_seconds,
    )
