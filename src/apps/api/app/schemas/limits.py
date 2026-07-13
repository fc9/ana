from pydantic import BaseModel


class LimitsRead(BaseModel):
    min_text_length: int
    max_attachments_per_message: int
