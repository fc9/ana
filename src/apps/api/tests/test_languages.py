from httpx import AsyncClient


async def test_list_languages(client: AsyncClient) -> None:
    response = await client.get("/languages")
    assert response.status_code == 200

    body = response.json()
    assert len(body) >= 1
    assert all(language["is_active"] for language in body)

    codes = {language["code"] for language in body}
    assert "en" in codes
    assert "pt-BR" in codes
