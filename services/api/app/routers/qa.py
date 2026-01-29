"""QA endpoints for observability and testing."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db import get_db
from app.middleware.observability import request_logger

router = APIRouter(prefix="/qa", tags=["qa"])


@router.get("/health-detailed")
async def health_detailed(db: Session = Depends(get_db)):
    """
    Get detailed health status including database connectivity,
    error counts, and response time metrics.
    """
    # Check database connectivity
    db_connected = False
    db_latency_ms = None
    db_error = None

    try:
        import time

        start = time.time()
        db.execute(text("SELECT 1"))
        db_latency_ms = round((time.time() - start) * 1000, 2)
        db_connected = True
    except Exception as e:
        db_error = str(e)

    # Get metrics from request logger
    metrics = request_logger.get_metrics()

    # Determine overall status
    status = "healthy"
    issues = []

    if not db_connected:
        status = "unhealthy"
        issues.append("Database connection failed")

    if metrics["error_rate_1min_percent"] > 10:
        status = "degraded" if status == "healthy" else status
        issues.append(f"High error rate: {metrics['error_rate_1min_percent']}%")

    if metrics["avg_response_time_ms"] > 2000:
        status = "degraded" if status == "healthy" else status
        issues.append(f"Slow response time: {metrics['avg_response_time_ms']}ms")

    return {
        "status": status,
        "issues": issues,
        "database": {
            "connected": db_connected,
            "latency_ms": db_latency_ms,
            "error": db_error,
        },
        "metrics": metrics,
    }


@router.get("/logs")
async def get_logs(
    limit: int = Query(100, ge=1, le=1000),
    level: str | None = Query(None, pattern="^(error|warning)$"),
    path: str | None = Query(None),
):
    """
    Get recent request logs with optional filtering.

    Args:
        limit: Maximum number of logs to return (1-1000)
        level: Filter by level - "error" (5xx) or "warning" (4xx+)
        path: Filter by path substring (e.g., "/auth")
    """
    logs = request_logger.get_logs(limit=limit, level=level, path=path)
    return {
        "count": len(logs),
        "logs": logs,
    }


@router.get("/metrics")
async def get_metrics():
    """Get current request metrics."""
    return request_logger.get_metrics()


@router.post("/reset-metrics")
async def reset_metrics():
    """Reset metrics counters (useful for starting fresh test runs)."""
    request_logger._error_count_1min = 0
    request_logger._request_count_1min = 0
    request_logger._total_response_time_1min = 0.0
    request_logger._logs.clear()
    return {"status": "ok", "message": "Metrics reset"}
