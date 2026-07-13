# Plano 003: User (`GET`/`PATCH /me`)

Branch: `user-me-endpoints`

## Contexto

Próxima entidade depois do esqueleto (Currency/Language/health/limits,
`plan-002`). `User` é simples (só `GET`/`PATCH /me`, sem
autenticação/multiusuário no MVP — ver `contracts/user.md` e
`06b-services.md` > UserService), mas introduz duas coisas novas que
o esqueleto anterior não precisou:

1. **Bootstrap do usuário único**: `03-users.sql` não tem seed (ao
   contrário de `01-currencies.sql`/`02-languages.sql`) — só existe o
   comentário "a aplicação atribui 'en' na criação do usuário". Isso
   nunca foi implementado ainda. Proposta: `UserService.get_current_user()`
   vira get-or-create — se a tabela `users` estiver vazia, cria uma
   linha com `language_id` = `Language` de código `en` e
   `name = "Usuário"` (placeholder, editável via `PATCH /me` depois).
   Sem migration de seed nova — fica na Service (regra de negócio, não
   schema).
2. **Primeiro caso de erro de validação de FK**: `PATCH /me` aceita
   `language_id` opcional — se não referenciar uma `Language`
   existente, `404` (mesmo padrão já usado em outros lugares pra id
   que não resolve, ver `06b-services.md` > `AttachmentService`).
   Ainda não existe mecanismo de erro de domínio → HTTP nesta
   aplicação (Currency/Language nunca falhavam) — este é o primeiro,
   então crio a peça mínima de infra (`app/core/exceptions.py` +
   handler em `main.py`), reaproveitável pelas próximas entidades.

Ambos os pontos são decisões de implementação, não de arquitetura —
sinalizados no plano original pra ajuste antes da implementação (ver
plano aprovado, sem mudanças pedidas).

## Escopo desta etapa

- `app/core/exceptions.py` — `NotFoundError(entity: str, resource_id)`;
- `main.py` — `@app.exception_handler(NotFoundError)` → `404`
  (`{"detail": "..."}`, formato padrão do FastAPI);
- Model: `app/models/user.py` (`id`, `language_id`, `name`,
  `created_at`, `updated_at`, relacionamento `language` →
  `app.models.language.Language`; sem relacionamento `projects` ainda
  — `Project` não existe);
- Schemas: `app/schemas/user.py` (`UserRead`, `UserUpdate` — `name`/
  `language_id` opcionais);
- Repository: `app/repositories/user.py` — `get_first(session)`,
  `create(session, language_id, name)`, `get_by_id(session, id)` (pra
  validar `language_id` em `PATCH /me`, reaproveitando o Model
  `Language` já existente);
- Service: `app/services/user_service.py` —
  `get_current_user(session)` (get-or-create, acima),
  `update_user(session, name=None, language_id=None)` (valida
  `language_id` via `Language`, `NotFoundError` se não existir;
  aplica só os campos informados);
- Route: `app/routes/me.py` — `GET /me`, `PATCH /me` (ver
  `03-backend.md` > Estrutura, já lista `routes/me.py`);
- registrar `me.router` em `main.py`;
- Testes: `tests/test_me.py` — `GET /me` (bootstrap não quebra, `id`
  estável entre chamadas), `PATCH /me` (nome + `language_id` válido,
  persiste), `PATCH /me` com `language_id` inválido (`404`).

## Detalhes de implementação

- **Bootstrap**: `get_current_user` faz `SELECT * FROM users LIMIT 1`
  via Repository; se vazio, busca `Language` por `code='en'` (já
  seedada) e cria o `User`. Sem lock/race-condition especial — MVP
  single-process, single-user, sem concorrência real nesse caminho.
- **`NotFoundError`**: `class NotFoundError(Exception): def __init__(self, entity: str, resource_id)`.
  Handler em `main.py` devolve
  `JSONResponse(404, {"detail": f"{entity} não encontrado: {resource_id}"})`
  — reaproveitável por qualquer Service futura que precise do mesmo
  padrão (ex: Project, Chat).
- **Route `PATCH /me`**: recebe `UserUpdate`, chama
  `user_service.update_user(session, **payload.model_dump(exclude_unset=True))`,
  devolve `UserRead.model_validate(user)`.

## Verificação

1. `uv run pytest` — os 3 casos de `test_me.py` passam, mais os 5 já
   existentes (sem regressão);
2. `uv run uvicorn app.main:app` manual: `curl localhost:8000/me` (cria
   o usuário na primeira chamada), `curl -X PATCH .../me -d
   '{"name": "Fabio"}'`, e um `language_id` inválido confirmando `404`.
