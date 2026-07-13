# Lesson 0002: esqueleto da aplicação FastAPI

Branch: `fastapi-app-skeleton` — plano em
`../../plans/plan-002-fastapi-app-skeleton.md`.

## Objetivo da tarefa

Criar a primeira aplicação FastAPI de verdade sobre o bootstrap de
Banco de Dados/Redis (`lesson-0001`): esqueleto completo de camadas
(Route → Service → Repository → Model → banco) usando Currency e
Language como prova de conceito, mais `GET /health`, `/version` e
`/limits` (sem banco), com testes automatizados.

## Principais desafios encontrados

- Rodar testes assíncronos (`pytest-asyncio`) contra o engine
  assíncrono compartilhado (`app/db/session.py`) quebrava de forma
  intermitente no Windows — só o teste de `/languages` falhava,
  não o de `/currencies`, o que escondeu a causa raiz por um momento
  (parecia específico da rota, não era).
- `@app.on_event("startup")` (API antiga do FastAPI) segue funcionando
  mas está depreciada — troquei por `lifespan` (`asynccontextmanager`)
  direto, sem custo adicional.

## Decisões arquiteturais relevantes

- Currency/Language ganharam Service "fino" (só repassa pro
  Repository) mesmo sem regra de negócio hoje — mantém a camada
  consistente com `03-backend.md` > Services para quando outras
  entidades (com regra de verdade) forem adicionadas.
- Testes rodam contra o Postgres de dev real (via `docker-compose`),
  sem mocks nem banco descartável — decisão consciente de manter
  simples no MVP (ver plano).
- Ver Pattern `../patterns/pattern-0002-thin-vertical-slice-crud.md`
  para a estrutura de arquivos replicável nas próximas entidades.

## Problemas enfrentados

`pytest` falhava só no teste de `/languages` com `AttributeError:
'NoneType' object has no attribute 'send'` dentro do driver de rede do
`asyncio` (Proactor), decorrente de `RuntimeError: Event loop is
closed` — uma conexão do pool do SQLAlchemy/asyncpg criada num evento
de loop de um teste sendo reutilizada depois que esse loop já tinha
sido fechado por outro teste.

## Soluções adotadas

`pytest-asyncio` por padrão cria um event loop novo **por teste**
(escopo `function`), mas o `engine` do SQLAlchemy é um singleton de
módulo (criado uma vez, no import) — os dois precisam compartilhar o
mesmo loop durante toda a sessão de testes. Configurei
`asyncio_default_fixture_loop_scope = "session"` **e**
`asyncio_default_test_loop_scope = "session"` em
`pyproject.toml` (`[tool.pytest.ini_options]`) — as duas chaves juntas
(não só a de fixture) resolveram de vez. Ver Anti-pattern
`../anti-patterns/anti-pattern-0002-pytest-asyncio-loop-scope-windows.md`.

## Recomendações para futuras implementações

- Sempre que um teste envolver o `engine`/`AsyncSessionLocal`
  compartilhado, confirmar que os dois ini options de loop scope do
  `pytest-asyncio` estão setados juntos — só um dos dois não é
  suficiente.
- Rodar a suíte pelo menos duas vezes seguidas ao introduzir um teste
  assíncrono novo que toque o banco — esse tipo de problema de loop é
  intermitente e pode passar na primeira tentativa por acaso da ordem
  de execução.
