# Plano 002: esqueleto da aplicação FastAPI

Branch: `fastapi-app-skeleton`

## Contexto

O bootstrap de Banco de Dados e Redis (`plan-001`) já está mesclado —
`app/core/config.py`, `app/db/session.py` (engine assíncrono) e
`app/db/migrate.py` existem e funcionam. Não existe nenhum código de
FastAPI ainda (sem `main.py`, sem Models/Schemas/Routes/Services). O
usuário pediu para seguir para a aplicação FastAPI em si.

O backend inteiro (todas as entidades de `06-models.md`) é grande
demais para uma etapa só — esta etapa cobre o **esqueleto da
aplicação** funcionando de ponta a ponta (Route → Service →
Repository → Model → banco), usando as duas entidades mais simples
como prova de conceito, mais os dois endpoints sem banco. Entidades
com regra de negócio de verdade (Provider, Config, Chat/Message etc.)
ficam para as próximas etapas, sobre essa mesma base.

## Escopo desta etapa

Entra (todos já documentados, sem decisão de arquitetura nova — ver
`03-backend.md` > Estrutura, `06-models.md` > Currency/Language/
Limits, `05-api.md` > Health/Version/Limits/Currencies/Languages):

- `app/main.py` — instância FastAPI, registro dos routers;
- `app/core/logging.py` — log estruturado (JSON lines), `project_id`/
  `chat_id`/`provider_id` via `contextvars`, conforme `03-backend.md`
  > Camadas > Logging (infraestrutura pronta para as próximas etapas —
  nenhuma rota desta etapa é escopada a projeto, então os contextvars
  não têm o que carregar ainda, mas o formatter/setup fica no lugar);
- `app/db/base.py` — `Base` declarativa comum (SQLAlchemy 2.0);
- Models: `app/models/currency.py`, `app/models/language.py`;
- Schemas: `app/schemas/currency.py` (`CurrencyRead`),
  `app/schemas/language.py` (`LanguageRead`),
  `app/schemas/limits.py` (`LimitsRead`);
- Repositories: `app/repositories/currency.py`,
  `app/repositories/language.py` — `list_active()`;
- Services: `app/services/currency_service.py`,
  `app/services/language_service.py` — repassam pro Repository (sem
  regra de negócio própria ainda, mas mantém a camada por consistência
  com `03-backend.md` > Services);
- Routes: `app/routes/health.py` (`GET /health`, `GET /version`),
  `app/routes/limits.py` (`GET /limits`), `app/routes/currencies.py`
  (`GET /currencies`), `app/routes/languages.py` (`GET /languages`);
- testes automatizados (`pytest` + `pytest-asyncio` + `httpx`, rodando
  contra o Postgres de dev já existente via `docker-compose` — sem
  mock, simplicidade em vez de infra extra de teste) para os 5
  endpoints acima.

Não entra (próximas etapas, quando essas entidades forem
implementadas): Provider/ProviderCredential/ProviderSubscription/
ProviderModel/ModelPrice (precisa de `core/security.py` >
CredentialCipher, `ProviderCacheService`), Project/Config, Chat/
Message/Attachment, TokenUsage, `core/security.py`, workers, realtime/
WebSocket.

## Arquivos a criar

```
src/apps/api/
├── app/
│   ├── main.py
│   ├── core/
│   │   ├── logging.py
│   │   └── version.py           # APP_VERSION = "0.1.0" (espelha pyproject.toml)
│   ├── db/
│   │   └── base.py
│   ├── models/
│   │   ├── currency.py
│   │   └── language.py
│   ├── schemas/
│   │   ├── currency.py
│   │   ├── language.py
│   │   └── limits.py
│   ├── repositories/
│   │   ├── currency.py
│   │   └── language.py
│   ├── services/
│   │   ├── currency_service.py
│   │   └── language_service.py
│   └── routes/
│       ├── health.py
│       ├── limits.py
│       ├── currencies.py
│       └── languages.py
└── tests/
    ├── conftest.py               # AsyncClient (httpx) contra o app FastAPI
    ├── test_health.py
    ├── test_limits.py
    ├── test_currencies.py
    └── test_languages.py
```

### Detalhes de implementação

- **`db/base.py`**: `class Base(DeclarativeBase): pass` — só isso,
  ponto único de herança pra todos os Models futuros.
- **Models**: `Mapped`/`mapped_column`, tipos batendo com
  `01-currencies.sql`/`02-languages.sql` (`id: Mapped[uuid.UUID]`,
  `code`, `name`, `symbol`, `rate_to_usd: Mapped[Decimal | None]`,
  `is_active`, `created_at`, `updated_at`; Language sem `symbol`, com
  `endonym`).
- **Repository → Service → Route**: `list_active()` filtra
  `is_active = true` (já existe índice parcial pra isso em ambas as
  tabelas, ver migrations 01/02) — reflete o uso real (popular
  dropdown, ver `05-api.md` > Currencies/Languages).
- **`core/logging.py`**: `logging.Filter` que injeta `project_id`/
  `chat_id`/`provider_id` de `contextvars.ContextVar` (default
  ausente/omitido do JSON quando não setado), formatter JSON
  (`json.dumps` de um dict fixo: `timestamp`, `level`, `logger`,
  `message`, + os campos de contexto presentes). `configure_logging()`
  chamado uma vez em `main.py` na criação do app.
- **`main.py`**: `app = FastAPI(title="Ana API", version=APP_VERSION)`,
  `configure_logging()`, `include_router` dos 4 routers.
- **Testes**: `conftest.py` cria um `httpx.AsyncClient` com
  `ASGITransport(app)` (sem subir servidor de verdade), reaproveitando
  o `engine`/sessão real de `app.db.session` — cada teste lê contra o
  Postgres de dev (mesmo que as migrations já popularam via seed, ver
  `01-currencies.sql`/`02-languages.sql`), sem fixture de banco
  descartável (fora de escopo agora — MVP, simplicidade).

### Dependências novas (`uv add`)

- `fastapi`, `uvicorn[standard]` (runtime);
- `pytest`, `pytest-asyncio`, `httpx` (dev — `uv add --dev`).

## Verificação

1. `uv add fastapi "uvicorn[standard]"` e `uv add --dev pytest
   pytest-asyncio httpx`;
2. `uv run uvicorn app.main:app --reload` — sobe sem erro;
3. `curl localhost:8000/health`, `/version`, `/limits`, `/currencies`,
   `/languages` — conferir shape e que `/currencies`/`/languages`
   retornam as linhas do seed (38 moedas, 25 idiomas);
4. `uv run pytest` — os 4 arquivos de teste passam contra o Postgres
   de dev (via `docker compose up -d`, já de pé).
