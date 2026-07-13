from sqlalchemy.ext.asyncio import AsyncSession

from app.models.currency import Currency
from app.repositories import currency as currency_repository


async def list_active(session: AsyncSession) -> list[Currency]:
    return await currency_repository.list_active(session)
