# Anti-pattern 0002: escopo de event loop padrão do `pytest-asyncio` com engine assíncrono compartilhado

## Problema observado

Testes assíncronos que usam um `AsyncEngine`/`AsyncSession` do
SQLAlchemy (asyncpg) definido como singleton de módulo (ex:
`app/db/session.py` > `engine`) falham de forma intermitente e
confusa — só alguns testes quebram, não todos os que tocam banco —
com `RuntimeError: Event loop is closed` ou
`AttributeError: 'NoneType' object has no attribute 'send'` vindo de
dentro do driver de rede do `asyncio` (visto no Windows, com
`ProactorEventLoop`).

## Contexto

Descoberto no esqueleto da aplicação FastAPI (ver Lesson
`../lessons/lesson-0002-fastapi-app-skeleton.md`), rodando
`pytest-asyncio` (`asyncio_mode = "auto"`) contra o `engine`
compartilhado de `app/db/session.py`.

## Causa raiz

`pytest-asyncio`, por padrão, cria um event loop **novo por teste**
(escopo `function`). O `engine`/pool de conexões, porém, é criado uma
única vez (no import do módulo) e mantém conexões vivas entre testes.
Uma conexão aberta sob o loop do teste A fica inválida assim que esse
loop é fechado ao final do teste A — se o pool a reutiliza no teste B
(sob um loop diferente, já novo), a operação falha ao tentar escrever
nesse socket, porque o transporte pertence a um loop que não existe
mais.

Definir só `asyncio_default_fixture_loop_scope = "session"` **não**
resolve sozinho — existe uma opção irmã,
`asyncio_default_test_loop_scope`, que controla o loop das próprias
funções de teste (não só das fixtures); sem as duas juntas, o
problema persiste.

## Consequências

Falhas intermitentes e específicas de alguns testes (não todos),
difíceis de reproduzir isoladamente (rodar só o teste que falhou,
sozinho, geralmente passa) — parece um bug no teste específico, mas é
um problema de configuração do event loop.

## Abordagem recomendada

Setar as duas opções juntas em `pyproject.toml` (`[tool.pytest.ini_options]`)
sempre que um engine/pool assíncrono for compartilhado entre testes:

```toml
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "session"
asyncio_default_test_loop_scope = "session"
```

Ver `src/apps/api/pyproject.toml`. Alternativa mais pesada (não
adotada aqui por simplicidade): recriar o `engine` por teste/fixture,
descartando-o ao final de cada um.
