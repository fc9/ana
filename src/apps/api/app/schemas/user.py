import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    language_id: uuid.UUID
    name: str
    created_at: datetime
    updated_at: datetime


class UserUpdate(BaseModel):
    name: str | None = None
    language_id: uuid.UUID | None = None
