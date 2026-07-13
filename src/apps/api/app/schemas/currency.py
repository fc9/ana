import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class CurrencyRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    code: str
    name: str
    symbol: str
    rate_to_usd: Decimal | None
    is_active: bool
    created_at: datetime
    updated_at: datetime
