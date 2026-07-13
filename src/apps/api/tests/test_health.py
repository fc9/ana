from httpx import AsyncClient

from app.core.version import APP_VERSION


async def test_health(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


async def test_version(client: AsyncClient) -> None:
    response = await client.get("/version")
    assert response.status_code == 200
    assert response.json() == {"version": APP_VERSION}
