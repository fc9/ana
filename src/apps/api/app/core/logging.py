import json
import logging
from contextvars import ContextVar
from datetime import datetime, timezone

# Propagados pela Route (extraídos do path) e setados manualmente por
# workers que não passam por uma Route (ver docs/dev/architecture/
# 03-backend.md > Camadas > Logging).
project_id_var: ContextVar[str | None] = ContextVar("project_id", default=None)
chat_id_var: ContextVar[str | None] = ContextVar("chat_id", default=None)
provider_id_var: ContextVar[str | None] = ContextVar("provider_id", default=None)


class _ContextFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.project_id = project_id_var.get()
        record.chat_id = chat_id_var.get()
        record.provider_id = provider_id_var.get()
        return True


class _JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        for field in ("project_id", "chat_id", "provider_id"):
            value = getattr(record, field, None)
            if value is not None:
                payload[field] = value
        return json.dumps(payload, ensure_ascii=False)


def configure_logging(level: int = logging.INFO) -> None:
    handler = logging.StreamHandler()
    handler.setFormatter(_JsonFormatter())
    handler.addFilter(_ContextFilter())

    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level)
