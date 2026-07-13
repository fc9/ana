from httpx import AsyncClient


async def test_list_currencies(client: AsyncClient) -> None:
    response = await client.get("/currencies")
    assert response.status_code == 200

    body = response.json()
    assert len(body) >= 1
    assert all(currency["is_active"] for currency in body)

    codes = {currency["code"] for currency in body}
    assert "USD" in codes

    usd = next(currency for currency in body if currency["code"] == "USD")
    assert usd["rate_to_usd"] == "1.00000000"
