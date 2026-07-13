# Pattern 0001: runner de migrations SQL sem Alembic

## Problema

As migrations da Ana são arquivos `.sql` puro, numerados
manualmente (`00-meta.sql`, `01-currencies.sql`, ..., `16-mcps.sql`,
ver `../../architecture/07-database.md`) — não são geradas a partir de
Models SQLAlchemy. Ferramentas como Alembic assumem o oposto (Models
como fonte da verdade, migration gerada por autogenerate), o que criaria
fricção sem necessidade real neste projeto.

## Solução adotada

Runner próprio e minimalista (`src/apps/api/app/db/migrate.py`):

1. conecta via `asyncpg` direto (sem depender do engine SQLAlchemy);
2. lê o último arquivo já aplicado na tabela `meta`
   (`key = 'last_migration'`) — se a tabela ainda não existe (`asyncpg.
   UndefinedTableError`), assume que nada foi aplicado ainda;
3. lista `db/migrations/*.sql`, ordenados lexicograficamente — a
   convenção de nomenclatura (`00`, `01`, ..., `05`, `05b`, `05c`,
   `06`, `06b`, ..., `16`) já garante que a ordem alfabética bate com
   a ordem de dependência entre tabelas;
4. aplica cada arquivo pendente numa transação própria (o SQL de cada
   arquivo pode ter múltiplos statements — `asyncpg.execute()` usa o
   protocolo simples do Postgres quando não há parâmetros, então
   múltiplos comandos separados por `;` funcionam sem split manual),
   atualizando `meta.last_migration` ao final de cada transação;
5. idempotente — rodar de novo sem migration pendente não faz nada
   (`nenhuma migration pendente`).

## Quando usar

Sempre que uma nova tabela/alteração de schema for adicionada: criar
o próximo `.sql` numerado em `db/migrations/` (seguindo a convenção de
nome) e rodar `uv run python -m app.db.migrate`.

## Quando evitar

Se o projeto um dia adotar Models como fonte da verdade do schema (não
é o caso hoje — ver `07-database.md`), migrar para uma ferramenta como
Alembic passa a fazer mais sentido, já que autogenerate de diff de
Models exige isso.

## Vantagens

- zero dependências extras (usa só `asyncpg`, já necessário para a
  conexão da aplicação);
- transparente — qualquer um lê o `.sql` puro e entende exatamente o
  que vai rodar, sem indireção de uma ferramenta de migration;
- idempotente e seguro para rodar em qualquer ambiente (dev, CI,
  produção) sem checagem manual de estado.

## Limitações

- forward-only — não há suporte a rollback/downgrade (consistente com
  a filosofia do MVP: simplicidade, evitar abstração prematura, ver
  `00-development.md` > Filosofia de Implementação);
- exige disciplina na numeração dos arquivos (nomes devem ordenar
  lexicograficamente na ordem correta de aplicação) — sem isso, a
  garantia de ordem quebra.

## Arquivos relacionados

- `src/apps/api/app/db/migrate.py`
- `src/apps/api/app/db/migrations/*.sql`
- `src/apps/api/app/core/config.py` (`Settings`, usado para os dados de
  conexão)
- `docs/dev/architecture/07-database.md`
