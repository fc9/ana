from httpx import AsyncClient

from app.core.config import settings


async def test_limits(client: AsyncClient) -> None:
    response = await client.get("/limits")
    assert response.status_code == 200
    assert response.json() == {
        "min_text_length": settings.min_text_length,
        "max_attachments_per_message": settings.max_attachments_per_message,
    }
