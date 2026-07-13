# Plano 001: bootstrap de Banco de Dados e Redis

Branch: `database-redis-bootstrap`

## Contexto

A documentação de arquitetura está madura e revisada. `src/` até este
ponto só tinha as migrations SQL (`00-16`) e os `.env`/`.env.example`
— nenhum código de aplicação existia ainda. O usuário pediu para
iniciar o desenvolvimento do MVP começando pela camada de Banco de
Dados e Redis, seguindo o que já está desenhado em `07-database.md`,
`08-redis.md`, `03-backend.md` (Estrutura) e `06-models.md`
(convenção SQLAlchemy 2.0 assíncrono).

Gerenciador de pacotes Python definido com o usuário: **uv**.

## Escopo desta etapa

Entra:

- projeto Python do `apps/api` (pyproject.toml via `uv`);
- conexão assíncrona com PostgreSQL (SQLAlchemy 2.0 + asyncpg);
- runner de migrations que aplica os `.sql` numerados de
  `db/migrations/` em ordem, rastreando o que já rodou;
- cliente Redis assíncrono (`redis.asyncio`);
- configuração central (`core/config.py`) lendo `src/.env`;
- verificação end-to-end (subir os containers, rodar as migrations,
  confirmar schema no Postgres e ping no Redis).

Não entra (fica para as próximas etapas, quando o Backend em si for
implementado):

- FastAPI app/rotas/services/Models SQLAlchemy;
- serviço `api` no `docker-compose.yml` (a API roda localmente via
  `uv run`, conectando no Postgres/Redis expostos em
  `127.0.0.1:5432`/`6379` — dockerizar a API fica para quando ela
  existir de fato).

## Achados resolvidos antes de codar

- `docker-compose.yml` (raiz) já definia `postgres:17` + `redis:8`,
  compatível com a arquitetura — sem alterações necessárias.
- Havia um `env.example` na raiz do repo, anterior ao redesenho de
  providers (`LLM_PROVIDER` singular contradizia a arquitetura atual
  de múltiplos providers/credenciais). Removido — `src/.env.example`
  é o arquivo realmente referenciado pelos docs.
- `infra/postgres/`/`infra/redis/` (raiz) e `tmp/infra/*.sql` (schema
  antigo, não relacionado) não foram tocados — fora do escopo desta
  etapa.

## Arquivos criados/editados

```
src/apps/api/
├── pyproject.toml          # uv, deps: sqlalchemy[asyncio], asyncpg,
│                           # redis, pydantic-settings
├── uv.lock
├── .python-version
└── app/
    ├── __init__.py
    ├── core/
    │   ├── __init__.py
    │   ├── config.py       # Settings (pydantic-settings) lendo src/.env
    │   └── redis.py        # get_redis() -> redis.asyncio.Redis
    └── db/
        ├── __init__.py
        ├── session.py       # create_async_engine + async_sessionmaker
        ├── migrate.py       # runner: aplica db/migrations/*.sql em ordem
        └── migrations/      # já existia (00-16), conteúdo não alterado

src/.env.example             # + DATABASE_URL/POSTGRES_*/REDIS_*
src/.env                     # idem (valores de dev, iguais ao compose)
env.example                  # removido (raiz)
```

### Decisões de implementação

- `db/migrate.py`: sem Alembic (migrations já são SQL puro numerado,
  não gerado a partir de Models). Runner conecta via `asyncpg` direto,
  lê `meta.last_migration`, aplica pendentes em ordem lexicográfica
  (já compatível com a numeração `00, 01, ..., 05, 05b, 05c, 06, 06b,
  ..., 16`), uma transação por arquivo.
- `POSTGRES_HOST`/`REDIS_HOST` usam `127.0.0.1` em vez de `localhost`
  — descoberto durante a verificação que a resolução dual-stack de
  `localhost` no asyncio trava a conexão do Redis neste ambiente
  (Windows); `127.0.0.1` resolve de forma confiável tanto para
  Postgres quanto Redis.

## Verificação (executada)

1. `docker compose up -d` — Postgres e Redis rodando;
2. `uv sync` em `src/apps/api`;
3. `uv run python -m app.db.migrate` — 19 migrations aplicadas sem
   erro, 20 tabelas confirmadas via `\dt`;
4. rodar de novo — `nenhuma migration pendente` (idempotência);
5. `get_redis().ping()`/`set`/`get` — Redis respondendo.
