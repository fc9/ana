import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class LanguageRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    code: str
    name: str
    endonym: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
