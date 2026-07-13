from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_session
from app.schemas.language import LanguageRead
from app.services import language_service

router = APIRouter()


@router.get("/languages", response_model=list[LanguageRead])
async def get_languages(session: AsyncSession = Depends(get_session)) -> list[LanguageRead]:
    languages = await language_service.list_active(session)
    return [LanguageRead.model_validate(language) for language in languages]
