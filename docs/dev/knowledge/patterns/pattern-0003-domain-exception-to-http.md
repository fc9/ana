# Pattern 0003: exceção de domínio → resposta HTTP

## Problema

Uma Service, ao validar uma referência recebida por payload (ex:
`language_id` em `UserUpdate`), precisa recusar um id que não resolve
pra nenhuma linha existente. A Service não deveria conhecer HTTP
(`03-backend.md` > Camadas: Services aplicam regra de negócio, Routes
tratam requisição/resposta) — levantar `fastapi.HTTPException` direto
na Service misturaria as duas camadas.

## Solução adotada

Exceção de domínio simples, sem nenhuma dependência de FastAPI, em
`app/core/exceptions.py`:

```python
class NotFoundError(Exception):
    def __init__(self, entity: str, resource_id: object) -> None:
        self.entity = entity
        self.resource_id = resource_id
        super().__init__(f"{entity} não encontrado: {resource_id}")
```

A Service levanta (`raise NotFoundError("Language", language_id)`,
ver `app/services/user_service.py`); um único handler global em
`main.py` traduz pra `404`:

```python
@app.exception_handler(NotFoundError)
async def not_found_error_handler(_: Request, exc: NotFoundError) -> JSONResponse:
    return JSONResponse(status_code=404, content={"detail": str(exc)})
```

A Route nunca precisa de `try/except` — o handler global cobre
qualquer `NotFoundError` levantada em qualquer Service.

## Quando usar

Toda vez que uma Service validar um id de referência (FK) recebido
por payload e precisar recusar um valor que não existe — passar a
entidade (nome legível) e o id recebido.

## Quando evitar

Erros que não são "recurso não encontrado" (ex: conflito de estado,
regra de negócio violada) merecem sua própria exceção de domínio +
handler (`409`, `422` etc.), seguindo o mesmo padrão — não forçar todo
erro a virar `NotFoundError`.

## Vantagens

- Service permanece sem nenhuma dependência de FastAPI/HTTP;
- um único handler cobre todas as entidades — nenhuma Route repete
  lógica de tradução de erro.

## Limitações

- mensagem de erro é sempre o mesmo formato (`"{entity} não
  encontrado: {id}"`) — se algum caso precisar de mensagem
  diferente, precisa de uma exceção própria.

## Arquivos relacionados

- `src/apps/api/app/core/exceptions.py`
- `src/apps/api/app/main.py` (handler)
- `src/apps/api/app/services/user_service.py` (primeiro uso)
