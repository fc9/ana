from fastapi import APIRouter

from app.core.config import settings
from app.schemas.limits import LimitsRead

router = APIRouter()


@router.get("/limits", response_model=LimitsRead)
async def get_limits() -> LimitsRead:
    return LimitsRead(
        min_text_length=settings.min_text_length,
        max_attachments_per_message=settings.max_attachments_per_message,
    )
