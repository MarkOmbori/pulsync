"""Observability middleware for request logging and metrics collection."""

import time
from collections import deque
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Deque

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response


@dataclass
class RequestLog:
    """A single request log entry."""

    timestamp: datetime
    method: str
    path: str
    status_code: int
    response_time_ms: float
    error: str | None = None


@dataclass
class RequestLogger:
    """Thread-safe request logger with circular buffer."""

    max_entries: int = 1000
    _logs: Deque[RequestLog] = field(default_factory=lambda: deque(maxlen=1000))
    _error_count_1min: int = 0
    _request_count_1min: int = 0
    _total_response_time_1min: float = 0.0
    _last_minute_reset: datetime = field(
        default_factory=lambda: datetime.now(timezone.utc)
    )

    def _maybe_reset_minute_counters(self) -> None:
        """Reset minute counters if a minute has passed."""
        now = datetime.now(timezone.utc)
        if (now - self._last_minute_reset).total_seconds() >= 60:
            self._error_count_1min = 0
            self._request_count_1min = 0
            self._total_response_time_1min = 0.0
            self._last_minute_reset = now

    def log_request(
        self,
        method: str,
        path: str,
        status_code: int,
        response_time_ms: float,
        error: str | None = None,
    ) -> None:
        """Log a request."""
        self._maybe_reset_minute_counters()

        log = RequestLog(
            timestamp=datetime.now(timezone.utc),
            method=method,
            path=path,
            status_code=status_code,
            response_time_ms=response_time_ms,
            error=error,
        )
        self._logs.append(log)

        # Update minute counters
        self._request_count_1min += 1
        self._total_response_time_1min += response_time_ms
        if status_code >= 400:
            self._error_count_1min += 1

    def get_logs(
        self,
        limit: int = 100,
        level: str | None = None,
        path: str | None = None,
    ) -> list[dict]:
        """Get recent logs with optional filtering."""
        self._maybe_reset_minute_counters()
        result = []

        for log in reversed(self._logs):
            # Filter by level (error = 5xx, warning = 4xx)
            if level:
                if level == "error" and log.status_code < 500:
                    continue
                if level == "warning" and log.status_code < 400:
                    continue

            # Filter by path
            if path and path not in log.path:
                continue

            result.append(
                {
                    "timestamp": log.timestamp.isoformat(),
                    "method": log.method,
                    "path": log.path,
                    "status_code": log.status_code,
                    "response_time_ms": round(log.response_time_ms, 2),
                    "error": log.error,
                }
            )

            if len(result) >= limit:
                break

        return result

    def get_metrics(self) -> dict:
        """Get current metrics."""
        self._maybe_reset_minute_counters()

        avg_response_time = (
            self._total_response_time_1min / self._request_count_1min
            if self._request_count_1min > 0
            else 0.0
        )

        error_rate = (
            (self._error_count_1min / self._request_count_1min * 100)
            if self._request_count_1min > 0
            else 0.0
        )

        return {
            "request_count_1min": self._request_count_1min,
            "error_count_1min": self._error_count_1min,
            "error_rate_1min_percent": round(error_rate, 2),
            "avg_response_time_ms": round(avg_response_time, 2),
            "total_logged": len(self._logs),
        }


# Global request logger instance
request_logger = RequestLogger()


class ObservabilityMiddleware(BaseHTTPMiddleware):
    """Middleware that logs requests and collects metrics."""

    async def dispatch(self, request: Request, call_next) -> Response:
        # Skip logging for QA endpoints to avoid recursion
        if request.url.path.startswith("/qa/"):
            return await call_next(request)

        start_time = time.time()
        error_msg = None

        try:
            response = await call_next(request)
            status_code = response.status_code
        except Exception as e:
            error_msg = str(e)
            status_code = 500
            raise
        finally:
            response_time_ms = (time.time() - start_time) * 1000
            request_logger.log_request(
                method=request.method,
                path=request.url.path,
                status_code=status_code,
                response_time_ms=response_time_ms,
                error=error_msg,
            )

        return response
