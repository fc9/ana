from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.language import Language


async def list_active(session: AsyncSession) -> list[Language]:
    result = await session.execute(
        select(Language).where(Language.is_active.is_(True)).order_by(Language.code)
    )
    return list(result.scalars())
