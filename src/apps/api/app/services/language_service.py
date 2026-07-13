from sqlalchemy.ext.asyncio import AsyncSession

from app.models.language import Language
from app.repositories import language as language_repository


async def list_active(session: AsyncSession) -> list[Language]:
    return await language_repository.list_active(session)
