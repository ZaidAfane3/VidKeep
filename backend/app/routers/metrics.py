"""
Prometheus metrics endpoint (T028).

Exposes application metrics in Prometheus format for monitoring.
"""

from fastapi import APIRouter
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response

router = APIRouter(tags=["Metrics"])


@router.get("/metrics")
async def metrics():
    """Prometheus-compatible metrics endpoint."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
