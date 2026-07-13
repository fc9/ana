import uuid

from httpx import AsyncClient


async def test_get_me_bootstraps_and_is_stable(client: AsyncClient) -> None:
    first = await client.get("/me")
    assert first.status_code == 200
    body = first.json()
    assert "id" in body
    assert "language_id" in body
    assert "name" in body

    second = await client.get("/me")
    assert second.status_code == 200
    assert second.json()["id"] == body["id"]


async def test_update_me(client: AsyncClient) -> None:
    languages = (await client.get("/languages")).json()
    pt_br = next(language for language in languages if language["code"] == "pt-BR")

    response = await client.patch("/me", json={"name": "Fabio", "language_id": pt_br["id"]})
    assert response.status_code == 200

    body = response.json()
    assert body["name"] == "Fabio"
    assert body["language_id"] == pt_br["id"]

    confirm = await client.get("/me")
    assert confirm.json()["name"] == "Fabio"
    assert confirm.json()["language_id"] == pt_br["id"]


async def test_update_me_invalid_language_returns_404(client: AsyncClient) -> None:
    response = await client.patch("/me", json={"language_id": str(uuid.uuid4())})
    assert response.status_code == 404
