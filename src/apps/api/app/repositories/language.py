import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.language import Language


async def list_active(session: AsyncSession) -> list[Language]:
    result = await session.execute(
        select(Language).where(Language.is_active.is_(True)).order_by(Language.code)
    )
    return list(result.scalars())


async def get_by_code(session: AsyncSession, code: str) -> Language | None:
    result = await session.execute(select(Language).where(Language.code == code))
    return result.scalars().first()


async def get_by_id(session: AsyncSession, language_id: uuid.UUID) -> Language | None:
    return await session.get(Language, language_id)
