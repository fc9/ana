from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.currency import Currency


async def list_active(session: AsyncSession) -> list[Currency]:
    result = await session.execute(
        select(Currency).where(Currency.is_active.is_(True)).order_by(Currency.code)
    )
    return list(result.scalars())
