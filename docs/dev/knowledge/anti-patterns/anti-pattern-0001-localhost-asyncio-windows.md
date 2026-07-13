# Anti-pattern 0001: `localhost` em clientes assíncronos no Windows

## Problema observado

`redis.asyncio.Redis.from_url("redis://localhost:6379/0")` (e,
potencialmente, outros clientes baseados em `asyncio` puro) trava até
estourar `TimeoutError` ao conectar, mesmo com o servidor saudável e
acessível — confirmado via `redis-cli ping` (dentro do container) e
via socket síncrono em Python no host, ambos respondendo
imediatamente.

## Contexto

Descoberto durante o bootstrap de conexão com Redis (ver Lesson
`../lessons/lesson-0001-database-redis-bootstrap.md`), rodando em
Windows com o `ProactorEventLoop` padrão do `asyncio`. `asyncpg`
(também assíncrono), com o mesmo host `localhost`, **não** apresentou
o problema.

## Causa raiz

`localhost` resolve para múltiplos endereços (IPv4 `127.0.0.1` e IPv6
`::1`). Dependendo da ordem/timeout que o resolver do `asyncio` tenta
cada um no Windows, a tentativa por um endereço que não aceita conexão
pode consumir o timeout inteiro antes de tentar o outro — cada
biblioteca implementa sua própria lógica de conexão/retry sobre
`asyncio`, então o mesmo host pode se comportar de forma diferente
entre bibliotecas (`asyncpg` não teve o problema; `redis.asyncio`
teve).

## Consequências

Timeout (`redis.exceptions.TimeoutError: Timeout connecting to
server`) sem nenhuma mensagem que aponte para o real problema — parece
"o Redis não está rodando" ou "porta errada", mas não é.

## Abordagem recomendada

Em desenvolvimento local no Windows, usar sempre `127.0.0.1` em vez de
`localhost` como host de conexão para bibliotecas assíncronas — evita
a ambiguidade de resolução dual-stack por completo. Ver
`../../architecture/07-database.md`/`08-redis.md` e
`../../../src/apps/api/app/core/config.py` (`Settings`), que já
adotam esse default.
