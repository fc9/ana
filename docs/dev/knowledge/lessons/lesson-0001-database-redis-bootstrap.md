# Lesson 0001: bootstrap de Banco de Dados e Redis

Branch: `database-redis-bootstrap` — plano em
`../../plans/plan-001-database-redis-bootstrap.md`.

## Objetivo da tarefa

Criar a primeira camada de código do Backend (`apps/api`): conexão
assíncrona com PostgreSQL (SQLAlchemy 2.0 + asyncpg), runner de
migrations para os `.sql` numerados já existentes, e cliente Redis
assíncrono — sem ainda implementar FastAPI/rotas/services.

## Principais desafios encontrados

- Nenhuma ferramenta de migration estava decidida na arquitetura — as
  migrations já eram SQL puro numerado (`00-16`), não gerado a partir
  de Models, então Alembic (que assume Models como fonte da verdade)
  não se encaixava sem fricção.
- Conexão assíncrona ao Redis via `localhost` travava (timeout) neste
  ambiente Windows, mesmo com o container saudável e acessível por
  `redis-cli`/socket síncrono.

## Decisões arquiteturais relevantes

- Gerenciador de pacotes: `uv`, decidido com o usuário (ver plano).
- Projeto do `apps/api` configurado como `package = false` no
  `pyproject.toml` (`[tool.uv]`) — não precisa ser instalável/buildável
  como um pacote Python, só roda via `uv run` a partir do próprio
  diretório (`app/` fica direto no `sys.path` por `python -m`).
- Runner de migration próprio (`app/db/migrate.py`), não Alembic — ver
  Pattern `../patterns/pattern-0001-sql-migration-runner.md`.

## Problemas enfrentados

`redis.asyncio.Redis.from_url("redis://localhost:6379/0")` estourava
`TimeoutError` na conexão, mesmo com `docker exec ana-redis redis-cli
ping` respondendo `PONG` e um socket síncrono em Python conectando sem
problema no mesmo host/porta. Isolei o problema trocando só o host
para `127.0.0.1` — funcionou de primeira. `asyncpg` com `localhost`,
por outro lado, nunca deu problema (rodou as 19 migrations sem
travar), então a instabilidade parece ser específica da combinação
`redis.asyncio` + resolução dual-stack (IPv4/IPv6) de `localhost` no
event loop do Windows (`ProactorEventLoop`), não um problema geral de
asyncio no Windows.

## Soluções adotadas

Troquei o default de `POSTGRES_HOST`/`REDIS_HOST` (em `Settings`,
`.env` e `.env.example`) de `localhost` para `127.0.0.1` — resolve o
problema do Redis e não tem nenhuma desvantagem para Postgres (mesmo
ambiente, mesma máquina).

## Recomendações para futuras implementações

- Em desenvolvimento local no Windows, preferir sempre `127.0.0.1` a
  `localhost` em qualquer URL de conexão assíncrona (Redis, mas
  possivelmente outras libs `asyncio`-nativas também) — não custa nada
  e evita esse tipo de timeout silencioso e difícil de diagnosticar.
- Ao adicionar uma nova biblioteca async, testar a conexão de verdade
  (não só assumir que "se o Postgres conectou, o resto conecta") —
  cada cliente implementa sua própria lógica de resolução de host.
