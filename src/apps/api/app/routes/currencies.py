from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_session
from app.schemas.currency import CurrencyRead
from app.services import currency_service

router = APIRouter()


@router.get("/currencies", response_model=list[CurrencyRead])
async def get_currencies(session: AsyncSession = Depends(get_session)) -> list[CurrencyRead]:
    currencies = await currency_service.list_active(session)
    return [CurrencyRead.model_validate(currency) for currency in currencies]
